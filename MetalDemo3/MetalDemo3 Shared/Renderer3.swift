//
//  Renderer.swift
//  MetalDemo1 Shared
//
//  Created by Torsten Kammer on 26.09.22.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

class Renderer3: NSObject, MTKViewDelegate {
    
    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState
    
    // Model data
    let vertexBuffer: MTLBuffer
    let elementBuffer: MTLBuffer
    let numElements: Int
    
    let texture: MTLTexture
    
    
    init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        guard let queue = self.device.makeCommandQueue() else { return nil }
        self.commandQueue = queue
        
        
        var vertices = [
            Vertex(position: SIMD2<Float>(-0.5, -0.5), texCoord: SIMD2<Float>(0.0, 1.0)),
            Vertex(position: SIMD2<Float>(-0.5, 0.5), texCoord: SIMD2<Float>(0.0, 0.0)),
            Vertex(position: SIMD2<Float>(0.5, -0.5), texCoord: SIMD2<Float>(1.0, 1.0)),
            Vertex(position: SIMD2<Float>(0.5, 0.5), texCoord: SIMD2<Float>(1.0, 0.0)),
        ]
        
        vertexBuffer = self.device.makeBuffer(bytes: &vertices, length: MemoryLayout<Vertex>.stride * vertices.count)!
        vertexBuffer.label = "Vertex buffer"
        
        var indices: [UInt32] = [ 0, 2, 1, 3 ]
        elementBuffer = self.device.makeBuffer(bytes: &indices, length: MemoryLayout<UInt32>.stride * indices.count)!
        numElements = indices.count
        
                        
        metalKitView.colorPixelFormat = MTLPixelFormat.bgra8Unorm
        metalKitView.sampleCount = 1
        
        let loader = MTKTextureLoader(device: device)
        let url = Bundle.main.url(forResource: "image", withExtension: "jpeg")!
        texture = try! loader.newTexture(URL: url, options: [
            .allocateMipmaps : true,
            .generateMipmaps : true,
        ])
        
        do {
            pipelineState = try Renderer3.buildRenderPipelineWithDevice(device: device,
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
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
        
    func draw(in view: MTKView) {
        /// Per frame updates hare
                
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            
            
            /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
            ///   holding onto the drawable and blocking the display pipeline any longer than necessary
            let renderPassDescriptor = view.currentRenderPassDescriptor
            
            if let renderPassDescriptor = renderPassDescriptor, let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                
                /// Final pass rendering code here
                renderEncoder.label = "Primary Render Encoder"
                
                renderEncoder.setCullMode(.back)
                
                renderEncoder.setFrontFacing(.counterClockwise)
                
                renderEncoder.setRenderPipelineState(pipelineState)
                                
                renderEncoder.setVertexBuffer(vertexBuffer, offset:0, index: BufferIndex.vertices.rawValue)
                renderEncoder.setFragmentTexture(texture, index: TextureIndex.color.rawValue)

                renderEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: numElements, indexType: .uint32, indexBuffer: elementBuffer, indexBufferOffset: 0)
                
                renderEncoder.endEncoding()
                
                if let drawable = view.currentDrawable {
                    commandBuffer.present(drawable)
                }
            }
            
            commandBuffer.commit()
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here
    }
}
