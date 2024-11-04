//
//  SongList.swift
//  Spotify-Karaoke
//
//  Created by takumi saito on 2021/01/24.
//

import SwiftUI
import BetterSafariView

struct SongList: View {
    @State var songs: [Song2]
    @State var name: String
    @State var machine: String
    @Binding var playing: Song2
    @Binding var showPlaying: Bool
    @Binding var offset: CGFloat
    @Binding var player_time: Double
    var body: some View {
        ZStack{
            List(songs){ song in
                song_cell(song: song, machine: machine, urlString: conv_url(song: song))
            }
            .navigationTitle(name)
            if UIDevice.current.userInterfaceIdiom == .phone{
                playing_view(playing: $playing, machine: $machine, showPlaying: $showPlaying, offset: $offset, player_time: $player_time)
            }
        }
    }
    
    func conv_url(song: Song2) -> String{
        if song.label == "なし"{
            return "https://joysound.biz/search/song.php?machine=\(machine)&word=\(song.name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)&matchs=1"
        }else{
            return "https://joysound.biz/search/song_detail.php?machine=\(machine)&id=\(song.label)"
        }
    }
}

//struct SongList_Previews: PreviewProvider {
//    static var previews: some View {
//        SongList(songs: [], name: "Playlist Title", machine: "N", playing: Song2(id: "", name: "", artist: "", label: ""))
//    }
//}
