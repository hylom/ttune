//
//  TTUContentMO.swift
//  ttune
//
//  Created by Hiromichi Matsushima on 2017/04/11.
//  Copyright © 2017年 Hiromichi Matsushima. All rights reserved.
//

import Foundation
import CoreData
import AVFoundation


class TTUContentMO: NSManagedObject {
/*
    @NSManaged var album: String
    @NSManaged var albumArtist: String
    @NSManaged var artist: String
    @NSManaged var genre: String
    @NSManaged var time: String
    @NSManaged var title: String
*/
    @NSManaged var acknowledgement: String
    @NSManaged var album: String
    @NSManaged var albumArtist: String
    @NSManaged var albumRating: Int16
    @NSManaged var arranger: String
    @NSManaged var artDirector: String
    @NSManaged var artist: String
    @NSManaged var artistID: Int64
    @NSManaged var author: String
    @NSManaged var beatsPerMin: Int16
    @NSManaged var bitRate: Int16
    @NSManaged var category: String
    @NSManaged var chapterName: String
    @NSManaged var chapterNumber: Int16
    @NSManaged var composer: String
    @NSManaged var conductor: String
    @NSManaged var contentRating: String
    @NSManaged var copyright: String
    @NSManaged var coverArt: AnyObject
    @NSManaged var credits: String
    @NSManaged var dateAtAdd: String
    @NSManaged var dateAtChange: String
    @NSManaged var descript: String
    @NSManaged var director: String
    @NSManaged var discCompilation: String
    @NSManaged var discNumber: Int16
    @NSManaged var encodedBy: String
    @NSManaged var encodingTool: String
    @NSManaged var episodeID: Int64
    @NSManaged var episodeNumber: Int64
    @NSManaged var eq: String
    @NSManaged var execProducer: String
    @NSManaged var genre: String
    @NSManaged var genreID: Int64
    @NSManaged var grouping: String
    @NSManaged var linerNotes: String
    @NSManaged var love: String
    @NSManaged var lyrics: String
    @NSManaged var onlineExtras: String
    @NSManaged var originalArtist: String
    @NSManaged var path: String
    @NSManaged var performer: String
    @NSManaged var phonogramRights: String
    @NSManaged var predefinedGenre: String
    @NSManaged var producer: String
    @NSManaged var program: String
    @NSManaged var publisher: String
    @NSManaged var recordCompany: String
    @NSManaged var releaseDate: String
    @NSManaged var sampleRate: String
    @NSManaged var season: String
    @NSManaged var size: String
    @NSManaged var skips: String
    @NSManaged var soloist: String
    @NSManaged var songName: String
    @NSManaged var sortAlbum: String
    @NSManaged var sortAlbumArtist: String
    @NSManaged var sortArtist: String
    @NSManaged var sortComposer: String
    @NSManaged var sortProgram: String
    @NSManaged var soundEngineer: String
    @NSManaged var thanks: String
    @NSManaged var time: String
    @NSManaged var title: String
    @NSManaged var trackNumber: Int16
    @NSManaged var trackSubTitle: String
    @NSManaged var userComment: String
    @NSManaged var userGenre: String
    @NSManaged var volume: Float
    @NSManaged var year: Int16

    override func awakeFromInsert() {
        super.awakeFromInsert()
        volume = 100.0
    }
    
    func setMetadataFrom(_ asset: AVAsset) {
        // format duration
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        let totalSec = CMTimeGetSeconds(asset.duration)
        if let t = formatter.string(from: totalSec) {
            time = t
        }
        
        for format in asset.availableMetadataFormats {
            if format == AVMetadataFormatiTunesMetadata {
                setItunesMetadata(asset)
            }
        }
    }
    
    fileprivate func setItunesMetadata(_ asset: AVAsset) {
        for metadata in AVMetadataItem.metadataItems(from: asset.metadata, withKey: nil, keySpace: AVMetadataKeySpaceiTunes) {
            /*
            guard let key = AVMetadataItem.identifierForKey(metadata.key!, keySpace: AVMetadataKeySpaceiTunes) else {
                continue
            }
            */
            guard let key = metadata.identifier else { continue }
            
            // k is like 'itsk/%A9nam', so split and decode
            let comps = key.components(separatedBy: "/")
            if (comps[0] != "itsk") {
                continue
            }
            let k = comps[1].replacingOccurrences(of: "%A9", with: "@")
            print("key:\(k)")

            if k == AVMetadataiTunesMetadataKeyAlbum {
                if let v = metadata.stringValue {
                    album = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyArtist {
                if let v = metadata.stringValue {
                    artist = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyUserComment {
                if let v = metadata.stringValue {
                    userComment = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyCoverArt {
                if let v = metadata.stringValue {
                    coverArt = v as AnyObject
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyCopyright {
                if let v = metadata.stringValue {
                    copyright = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyReleaseDate {
                if let v = metadata.stringValue {
                    releaseDate = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyEncodedBy {
                if let v = metadata.stringValue {
                    encodedBy = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyPredefinedGenre {
                if let v = metadata.stringValue {
                    predefinedGenre = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyUserGenre {
                if let v = metadata.stringValue {
                    userGenre = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeySongName {
                if let v = metadata.stringValue {
                    songName = v
                    title = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyTrackSubTitle {
                if let v = metadata.stringValue {
                    trackSubTitle = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyEncodingTool {
                if let v = metadata.stringValue {
                    encodingTool = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyComposer {
                if let v = metadata.stringValue {
                    composer = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyAlbumArtist {
                if let v = metadata.stringValue {
                    albumArtist = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyDiscCompilation {
                if let v = metadata.stringValue {
                    discCompilation = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyDiscNumber {
                if let v = metadata.numberValue {
                    discNumber = Int16(Int(v))
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyGenreID {
                if let v = metadata.numberValue {
                    genreID = Int64(Int(v))
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyGrouping {
                if let v = metadata.stringValue {
                    grouping = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyContentRating {
                if let v = metadata.stringValue {
                    contentRating = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyBeatsPerMin {
                if let v = metadata.numberValue {
                    beatsPerMin = Int16(Int(v))
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyTrackNumber {
                if let v = metadata.numberValue {
                    trackNumber = Int16(Int(v))
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyArtDirector {
                if let v = metadata.stringValue {
                    artDirector = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyArranger {
                if let v = metadata.stringValue {
                    arranger = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyAuthor {
                if let v = metadata.stringValue {
                    author = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyLyrics {
                if let v = metadata.stringValue {
                    lyrics = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyAcknowledgement {
                if let v = metadata.stringValue {
                    acknowledgement = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyConductor {
                if let v = metadata.stringValue {
                    conductor = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyDescription {
                if let v = metadata.stringValue {
                    descript = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyDirector {
                if let v = metadata.stringValue {
                    director = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyEQ {
                if let v = metadata.stringValue {
                    eq = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyLinerNotes {
                if let v = metadata.stringValue {
                    linerNotes = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyRecordCompany {
                if let v = metadata.stringValue {
                    recordCompany = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyOriginalArtist {
                if let v = metadata.stringValue {
                    originalArtist = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyPhonogramRights {
                if let v = metadata.stringValue {
                    phonogramRights = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyProducer {
                if let v = metadata.stringValue {
                    producer = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyPerformer {
                if let v = metadata.stringValue {
                    performer = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyPublisher {
                if let v = metadata.stringValue {
                    publisher = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeySoundEngineer {
                if let v = metadata.stringValue {
                    soundEngineer = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeySoloist {
                if let v = metadata.stringValue {
                    soloist = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyCredits {
                if let v = metadata.stringValue {
                    credits = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyThanks {
                if let v = metadata.stringValue {
                    thanks = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyOnlineExtras {
                if let v = metadata.stringValue {
                    onlineExtras = v
                }
            }
                
            else if k == AVMetadataiTunesMetadataKeyExecProducer {
                if let v = metadata.stringValue {
                    execProducer = v
                }
            }
            

            
        }
    }
    
}
