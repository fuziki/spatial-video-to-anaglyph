//
//  Movie.swift
//  spatial-video-to-anaglyph
//
//  Created by fuziki on 2024/01/23.
//

import CoreTransferable

struct Movie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let url = URL.temporaryDirectory.appending(path: "tmp.mp4")

            if FileManager.default.fileExists(atPath: url.path()) {
                try FileManager.default.removeItem(at: url)
            }

            try FileManager.default.copyItem(at: received.file, to: url)
            return Self.init(url: url)
        }
    }
}
