//
//  ContentView.swift
//  spatial-video-to-anaglyph
//
//  Created by fuziki on 2024/01/23.
//

import AVFoundation
import SwiftUI
import Photos
import PhotosUI

struct ContentView: View {
    @ObservedObject var vm = ContentViewModel()

    var body: some View {
        if let image = vm.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()
        } else {
            let selection = Binding<PhotosPickerItem?> {
                vm.selectedItem
            } set: { (item: PhotosPickerItem?) in
                vm.selected(item: item)
            }
            PhotosPicker("Select Spatial Video", selection: selection, matching: .videos)
        }
    }
}

@MainActor
class ContentViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
    @Published var image: UIImage?

    var player: AVPlayer!
    var videoOutput: AVPlayerVideoOutput!

    var displayLink: CADisplayLink!

    let kernel: CIColorKernel = {
        let url = Bundle.main.url(forResource: "default", withExtension: "metallib")!
        let data = try! Data(contentsOf: url)
        return try! CIColorKernel(functionName: "anaglyph", fromMetalLibraryData: data)
    }()

    let context = CIContext()

    func selected(item: PhotosPickerItem?) {
        Task {
            let movie = try! await item!.loadTransferable(type: Movie.self)!
            handle(asset: AVAsset(url: movie.url))
        }
    }

    func handle(asset: AVAsset) {
        player = AVPlayer(playerItem: AVPlayerItem(asset: asset))

        let specification = AVVideoOutputSpecification(tagCollections: [.stereoscopicForVideoOutput()])
        videoOutput = AVPlayerVideoOutput(specification: specification)
        player.videoOutput = videoOutput

        displayLink = CADisplayLink(target: self, selector: #selector(onDisplayLink(link:)))
        displayLink.add(to: .main, forMode: .common)
        player.play()
    }

    @objc func onDisplayLink(link: CADisplayLink) {
        guard let taggedBuffers = videoOutput.taggedBuffers(forHostTime: CMClockGetTime(CMClockGetHostTimeClock())) else { return }

        let buffL = taggedBuffers.taggedBufferGroup.first { $0.tags.contains(.stereoView(.leftEye)) }!
        let buffR = taggedBuffers.taggedBufferGroup.first { $0.tags.contains(.stereoView(.rightEye)) }!

        guard case let .pixelBuffer(pbL) = buffL.buffer,
              case let .pixelBuffer(pbR) = buffR.buffer else { return }

        let ciL = CIImage(cvPixelBuffer: pbL)
        let ciR = CIImage(cvPixelBuffer: pbR)

        let ci = kernel.apply(extent: ciL.extent, arguments: [ciL, ciR])!
        let cg =  context.createCGImage(ci, from: ci.extent)!
        image = UIImage(cgImage: cg)
    }
}
