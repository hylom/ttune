import re

avmetadata_keys = """AVMetadataiTunesMetadataKeyAlbum
AVMetadataiTunesMetadataKeyArtist
AVMetadataiTunesMetadataKeyUserComment
AVMetadataiTunesMetadataKeyCoverArt
AVMetadataiTunesMetadataKeyCopyright
AVMetadataiTunesMetadataKeyReleaseDate
AVMetadataiTunesMetadataKeyEncodedBy
AVMetadataiTunesMetadataKeyPredefinedGenre
AVMetadataiTunesMetadataKeyUserGenre
AVMetadataiTunesMetadataKeySongName
AVMetadataiTunesMetadataKeyTrackSubTitle
AVMetadataiTunesMetadataKeyEncodingTool
AVMetadataiTunesMetadataKeyComposer
AVMetadataiTunesMetadataKeyAlbumArtist
AVMetadataiTunesMetadataKeyAccountKind
AVMetadataiTunesMetadataKeyAppleID
AVMetadataiTunesMetadataKeyArtistID
AVMetadataiTunesMetadataKeySongID
AVMetadataiTunesMetadataKeyDiscCompilation
AVMetadataiTunesMetadataKeyDiscNumber
AVMetadataiTunesMetadataKeyGenreID
AVMetadataiTunesMetadataKeyGrouping
AVMetadataiTunesMetadataKeyPlaylistID
AVMetadataiTunesMetadataKeyContentRating
AVMetadataiTunesMetadataKeyBeatsPerMin
AVMetadataiTunesMetadataKeyTrackNumber
AVMetadataiTunesMetadataKeyArtDirector
AVMetadataiTunesMetadataKeyArranger
AVMetadataiTunesMetadataKeyAuthor
AVMetadataiTunesMetadataKeyLyrics
AVMetadataiTunesMetadataKeyAcknowledgement
AVMetadataiTunesMetadataKeyConductor
AVMetadataiTunesMetadataKeyDescription
AVMetadataiTunesMetadataKeyDirector
AVMetadataiTunesMetadataKeyEQ
AVMetadataiTunesMetadataKeyLinerNotes
AVMetadataiTunesMetadataKeyRecordCompany
AVMetadataiTunesMetadataKeyOriginalArtist
AVMetadataiTunesMetadataKeyPhonogramRights
AVMetadataiTunesMetadataKeyProducer
AVMetadataiTunesMetadataKeyPerformer
AVMetadataiTunesMetadataKeyPublisher
AVMetadataiTunesMetadataKeySoundEngineer
AVMetadataiTunesMetadataKeySoloist
AVMetadataiTunesMetadataKeyCredits
AVMetadataiTunesMetadataKeyThanks
AVMetadataiTunesMetadataKeyOnlineExtras
AVMetadataiTunesMetadataKeyExecProducer
"""

template = """else if k == {0} {{
    if let v = metadata.stringValue {{
        {1} = v
    }}
}}
"""

def main():
    metadata_keys = avmetadata_keys.split('\n')
    metadata_values = [x.replace('AVMetadataiTunesMetadataKey', '') for x in metadata_keys]
    metadata_values = [re.sub(r'^([A-Z]+)',
                            lambda i:i.group(1).lower(),
                            x) for x in metadata_values]
    for i in range(0, len(metadata_keys)-1):
        print template.format(metadata_keys[i], metadata_values[i])

if __name__ == '__main__':
    main()
