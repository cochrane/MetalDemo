//
//  Renderer2.swift
//  MetalDemo2 Shared
//
//  Created by Torsten Kammer on 28.09.22.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

class Renderer2: NSObject, MTKViewDelegate {
    
    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    // Shader that draws our data
    var pipelineState: MTLRenderPipelineState
    
    // The data for the model
    let vertexBuffer: MTLBuffer
    let elementBuffer: MTLBuffer
    let numElements: Int
    
    // The depth buffer
    var depthBuffer: MTLTexture! = nil
    let depthState: MTLDepthStencilState
    
    // The additional data
    var projectionMatrix = matrix_float4x4()
    var viewMatrix = matrix_float4x4()
    var modelMatrix = matrix_float4x4()
    var angle: Float = 0.0
    var lastUpdate = Date.timeIntervalSinceReferenceDate
    
    init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        guard let queue = self.device.makeCommandQueue() else { return nil }
        self.commandQueue = queue
        
        // Load model
        var (vertices, elements) = Renderer2.loadTeapot()
        
        vertexBuffer = self.device.makeBuffer(bytes: &vertices, length: MemoryLayout<Vertex>.stride * vertices.count)!
        vertexBuffer.label = "Vertex buffer"
        
        elementBuffer = self.device.makeBuffer(bytes: &elements, length: MemoryLayout<UInt32>.stride * elements.count)!
        numElements = elements.count
        
        // Position camera
        viewMatrix = Renderer2.matrixLookAt(direction: SIMD3<Float>(x: 0.0, y: -0.5, z: -1.0), eyePosition: SIMD3<Float>(x: 0.0, y: 2.0, z: 5))
                      
        // Set up view
        metalKitView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        metalKitView.sampleCount = 1
        
        // Set up depth testing
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.isDepthWriteEnabled = true
        depthStateDescriptor.depthCompareFunction = .less
        depthStateDescriptor.label = "Default depth state"
        depthState = device.makeDepthStencilState(descriptor: depthStateDescriptor)!
        
        do {
            pipelineState = try Renderer2.buildRenderPipelineWithDevice(device: device,
                                                                       metalKitView: metalKitView)
        } catch {
            print("Unable to compile render pipeline state.  Error info: \(error)")
            return nil
        }
        
        
        super.init()
    }
    
    class func buildRenderPipelineWithDevice(device: MTLDevice,
                                             metalKitView: MTKView) throws -> MTLRenderPipelineState {
        /// Build a render state pipeline object
        
        let library = device.makeDefaultLibrary()
        
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
        pipelineDescriptor.rasterSampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
        
    func draw(in view: MTKView) {
        /// Per frame updates hare
                
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            
            // Update the model matrix to make the teapot spin
            let rightNow = Date.timeIntervalSinceReferenceDate
            let delta = Float(lastUpdate - rightNow)
            lastUpdate = rightNow
            angle = angle + delta * 0.5
            if angle >= Float.pi*2 {
                angle -= Float.pi*2
            }
            modelMatrix = matrix_float4x4(SIMD4<Float>(x: cos(angle), y: 0, z: sin(angle), w: 0),
                                          SIMD4<Float>(x: 0, y: 1, z: 0, w: 0),
                                          SIMD4<Float>(x: sin(-angle), y: 0, z: cos(angle), w: 0),
                                          SIMD4<Float>(x: 0, y: -2, z: 0, w: 1) )
            
            
            /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
            ///   holding onto the drawable and blocking the display pipeline any longer than necessary
            guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
                return
            }
            
            renderPassDescriptor.depthAttachment.texture = depthBuffer
            renderPassDescriptor.depthAttachment.loadAction = .clear
            renderPassDescriptor.depthAttachment.storeAction = .dontCare
            
            if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                
                /// Final pass rendering code here
                renderEncoder.label = "Primary Render Encoder"
                
                renderEncoder.setCullMode(.none)
                renderEncoder.setFrontFacing(.counterClockwise)
                
                // Use depth testing
                renderEncoder.setDepthStencilState(depthState)
                
                // Use shader
                renderEncoder.setRenderPipelineState(pipelineState)
                
                // Calculate the final matrices and upload them directly without any buffer
                let modelView = viewMatrix * modelMatrix
                let modelViewProjection = projectionMatrix * modelView
                var matricesBuffer = Matrices(modelViewProjection: modelViewProjection, modelView: modelView)
                renderEncoder.setVertexBytes(&matricesBuffer, length: MemoryLayout<Matrices>.stride, index: BufferIndex.matrices.rawValue)
                                
                // Use vertices from our model
                renderEncoder.setVertexBuffer(vertexBuffer, offset:0, index: BufferIndex.vertices.rawValue)
                
                // Draw using indices
                renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: numElements, indexType: .uint32, indexBuffer: elementBuffer, indexBufferOffset: 0)
                
                renderEncoder.endEncoding()
                
                if let drawable = view.currentDrawable {
                    commandBuffer.present(drawable)
                }
            }
            
            commandBuffer.commit()
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Calculate new projection matrix
        let aspect = Float(size.width / size.height)
        let angle: Float = 90 * Float.pi / 360.0
        let near: Float = 0.1
        let far: Float = 10.0
        
        let ymax = near * tan(angle)
        let xmax = ymax * aspect
        projectionMatrix = simd_float4x4(SIMD4<Float>(x: near/xmax, y: 0, z: 0, w: 0),
                                         SIMD4<Float>(x: 0, y: near/ymax, z: 0, w: 0),
                                         SIMD4<Float>(x: 0, y: 0, z: -(far+near)/(far-near), w: -1),
                                         SIMD4<Float>(x: 0, y: 0, z: -(2*far*near)/(far-near), w: 0))
        
        let depthBufferDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: Int(size.width), height: Int(size.height), mipmapped: false)
        depthBufferDescriptor.usage = .renderTarget
        depthBufferDescriptor.storageMode = .private
        depthBufferDescriptor.allowGPUOptimizedContents = true
        
        depthBuffer = device.makeTexture(descriptor: depthBufferDescriptor)
        depthBuffer.label = "Depth buffer"
    }
    
    /// Helper: Basic "look at" matrix
    static func matrixLookAt(direction: SIMD3<Float>, eyePosition: SIMD3<Float>) -> matrix_float4x4 {
        let normalizedDirection = normalize(direction)
        let rightVector = normalize(cross(normalizedDirection, SIMD3<Float>(x: 0, y: 1, z: 0)))
        let upVector = normalize(cross(rightVector, normalizedDirection))
        
        let positionOfCamera = matrix_float4x4(SIMD4<Float>(rightVector, 0),
                                               SIMD4<Float>(upVector, 0),
                                               SIMD4<Float>(-normalizedDirection, 0),
                                               SIMD4<Float>(eyePosition, 1))
        
        return positionOfCamera.inverse
    }
    
    /// Helper: Loads one specific OBJ file. Not a generic obj loaders
    static func loadTeapot() -> ([Vertex], [Int32]) {
        let url = Bundle.main.url(forResource: "teapot", withExtension: "obj")!
        let contents = try! String(contentsOf: url)
        let scanner = Scanner(string: contents)
        
        var vertices: [Vertex] = []
        while scanner.scanString("v") != nil {
            let x = scanner.scanFloat()!
            let y = scanner.scanFloat()!
            let z = scanner.scanFloat()!
            vertices.append(Vertex(position: SIMD3<Float>(x: x, y: y, z: z), normal: SIMD3<Float>(repeating: 0)))
        }
        
        var elements: [Int32] = []
        while scanner.scanString("f") != nil {
            let index0 = scanner.scanInt32()! - 1
            let index1 = scanner.scanInt32()! - 1
            let index2 = scanner.scanInt32()! - 1
            elements.append(index0)
            elements.append(index1)
            elements.append(index2)
            
            // Calculate normal vectors for lighting
            let position0 = vertices[Int(index0)].position
            let position1 = vertices[Int(index1)].position
            let position2 = vertices[Int(index2)].position
            let normal = normalize(cross(position2 - position0, position1 - position0))
            vertices[Int(index0)].normal += normal
            vertices[Int(index1)].normal += normal
            vertices[Int(index2)].normal += normal
        }
        for var vertex in vertices {
            vertex.normal = normalize(vertex.normal)
        }
        
        return (vertices, elements)
    }
}
