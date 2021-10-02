//
//  Renderer.swift
//  streamProjectOne
//
//  Created by Dmitry Tabakerov on 27.01.21.
//

import MetalKit
import MetalPerformanceShaders


class TwoColorPhysarumRenderer : NSObject {
    let dimentions = 2000
    var colors: [SIMD3<Float>] = []
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    var renderPipelineState: MTLRenderPipelineState!
    var computeMovePipelineState: MTLComputePipelineState!
    var computeRotatePipelineState: MTLComputePipelineState!
    var blurPipelineState: MTLComputePipelineState!
    var vertexData: [Float]
    var vertexBuffer: MTLBuffer
    var textureRead: MTLTexture
    var textureWrite: MTLTexture
    var particles: [Particle]
    var particlesBuffer: MTLBuffer
    
    init(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue()
        else {
            fatalError("GPU does not collaborate!:(")
        }
        TwoColorPhysarumRenderer.device = device
        TwoColorPhysarumRenderer.commandQueue = commandQueue
        let hue = CGFloat(sin(Float.random(in: 0...Float.pi)))
        let saturation = CGFloat(Float.random(in: 0.4...0.8))
        let brightness = CGFloat(Float.random(in: 0.4...0.7))
        let color1 = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
        let color2 = UIColor(hue: 1.0 - hue, saturation: saturation * CGFloat(Float.random(in: 0.8...1.2)), brightness: brightness * CGFloat(Float.random(in: 0.8...1.2)), alpha: 1.0)
        let mult1 = Float.random(in: 3...8)
        let mult2 = Float.random(in: 3...8)
        var red : CGFloat = 0
        var green : CGFloat = 0
        var blue : CGFloat = 0
        var alpha : CGFloat = 0
        
        
        print(color1)
        print(color2)
        
        color1.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        colors.append(SIMD3<Float>(Float(red), Float(green), Float(blue)) * mult1)
        
        color2.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        colors.append(SIMD3<Float>(Float(red), Float(green), Float(blue)) * mult2)
        
        metalView.device = device
        
        particles = []
        
        
        for _ in 1...3000 {
            particles.append(Particle(
                                Position: SIMD2<Float>(
                                    Float.random(in: 0.0...Float(dimentions)),
                                    Float.random(in: 0.0...Float(dimentions))
                                ),
                                Direction: SIMD2<Float>(
                                    Float.random(in: -3.0...3.0),
                                    Float.random(in: -3.0...3.0)
                                ),
                                Intensity: colors[Int.random(in: 0...1)]
                ))
        }
        
        particlesBuffer = device.makeBuffer(bytes: particles, length: MemoryLayout<Particle>.stride * particles.count, options: [])!
        
        vertexData = [-1.0, -1.0, 0.0, 1.0, //0.0, 0.0,
                       1.0, -1.0, 0.0, 1.0, //1.0, 0.0,
                      -1.0,  1.0, 0.0, 1.0, //0.0, 1.0,
                      -1.0,  1.0, 0.0, 1.0, //0.0, 1.0,
                       1.0, -1.0, 0.0, 1.0, //1.0, 0.0,
                       1.0,  1.0, 0.0, 1.0, //1.0, 1.0
                      ]
        vertexBuffer = device.makeBuffer(bytes: vertexData,
                                         length: MemoryLayout<Float>.size * vertexData.count,
                                         options: [])!
        
        let library = device.makeDefaultLibrary()
        
        let computeFunctionMove = library?.makeFunction(name: "compute_function_move")
        let computeFunctionRotate = library?.makeFunction(name: "compute_function_rotate")
        let fragmentFunction = library?.makeFunction(name: "fragment_function")
        let vertexFunction = library?.makeFunction(name: "vertex_function")
        let blurFunction = library?.makeFunction(name: "blur_function")
        
        let computePipelineDescriptor = MTLComputePipelineDescriptor()
        //computePipelineDescriptor.computeFunction = computeFunctionMove
        //computePipelineDescriptor.computeFunction = computeFunctionRotate
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
            computeMovePipelineState = try device.makeComputePipelineState(function: computeFunctionMove!)
            computeRotatePipelineState = try device.makeComputePipelineState(function: computeFunctionRotate!)
            blurPipelineState = try device.makeComputePipelineState(function: blurFunction!)
        } catch let error {
            print(error.localizedDescription)
        }
        print("DRAWABLE SIZE \(metalView.frame.width) \(metalView.frame.height)")
        let textureDescriptorRead = MTLTextureDescriptor()
        textureDescriptorRead.storageMode = .private
        textureDescriptorRead.usage = [.shaderRead]
        textureDescriptorRead.pixelFormat = .rgba32Float
        textureDescriptorRead.width = Int(metalView.drawableSize.height)
        textureDescriptorRead.height = Int(metalView.drawableSize.width)
        textureDescriptorRead.depth = 1
        textureRead = device.makeTexture(descriptor: textureDescriptorRead)!
        
        let textureDescriptorWrite = MTLTextureDescriptor()
        textureDescriptorWrite.storageMode = .private
        textureDescriptorWrite.usage = [.shaderWrite]
        textureDescriptorWrite.pixelFormat = .rgba32Float
        textureDescriptorWrite.width = Int(metalView.drawableSize.height)
        textureDescriptorWrite.height = Int(metalView.drawableSize.width)
        textureDescriptorWrite.depth = 1
        textureWrite = device.makeTexture(descriptor: textureDescriptorWrite)!
        
        super.init()
        
        metalView.clearColor = MTLClearColor(red: 0.3, green: 0.9, blue: 0.8, alpha: 1.0)
        metalView.delegate = self
        
    }
}

extension TwoColorPhysarumRenderer : MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        
        
        guard
            let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = TwoColorPhysarumRenderer.commandQueue.makeCommandBuffer()
        else {
            return
        }
        
        
        guard let computeMoveEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        
        computeMoveEncoder.setComputePipelineState(computeMovePipelineState)
        computeMoveEncoder.setTexture(textureWrite, index: 0)
        computeMoveEncoder.setBuffer(particlesBuffer, offset: 0, index: 0)
        computeMoveEncoder.dispatchThreadgroups(MTLSize(width: particles.count, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
        computeMoveEncoder.endEncoding()
        
        guard let blitEncoder1 = commandBuffer.makeBlitCommandEncoder() else {
            return
        }
        blitEncoder1.copy(from: textureWrite, to: textureRead)
        blitEncoder1.endEncoding()
        
        
        guard let computeRotateEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        computeRotateEncoder.setComputePipelineState(computeRotatePipelineState)
        computeRotateEncoder.setTexture(textureRead, index: 0)
        computeRotateEncoder.setBuffer(particlesBuffer, offset: 0, index: 0)
        computeRotateEncoder.dispatchThreadgroups(MTLSize(width: particles.count, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
        computeRotateEncoder.endEncoding()
        
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }
        
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(textureRead, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
        
        /*
        let blur = MPSImageGaussianBlur(device: Renderer.device, sigma: 0.50)
        blur.label = "MPSBlur"
        blur.encode(commandBuffer: commandBuffer, sourceTexture: textureRead, destinationTexture: textureWrite)
        */
        
        guard let blurEncoder = commandBuffer.makeComputeCommandEncoder() else {
                    return
                }
        
        blurEncoder.setComputePipelineState(blurPipelineState)
        blurEncoder.setTexture(textureRead, index: 0)
        blurEncoder.setTexture(textureWrite, index: 1)
                //blurEncoder.setBytes(&Renderer.uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
                
        var width = blurPipelineState.threadExecutionWidth
        var height = blurPipelineState.maxTotalThreadsPerThreadgroup / width
        
        let threadsPerThreadgroup = MTLSizeMake(width, height, 1)
        
        width = Int(Int(view.drawableSize.height) / Int(width))
        height = Int(Int(view.drawableSize.width) / Int(height))
        
        let threadsPerGrid = MTLSizeMake(width, height, 1)
                
        blurEncoder.dispatchThreadgroups(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
                
        blurEncoder.endEncoding()
        
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
