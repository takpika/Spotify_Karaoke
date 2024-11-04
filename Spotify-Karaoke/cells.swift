//
//  NavigationLink.swift
//  Spotify-Karaoke
//
//  Created by takumi saito on 2021/01/24.
//

import SwiftUI
import BetterSafariView

struct playlist_cell: View {
    let playlist: Playlist2
    var body: some View {
        HStack{
            if playlist.id == "favorite"{
                Image(systemName: "star")
            }
            VStack(alignment: .leading){
                Text(playlist.name)
                Text("\(playlist.songs.count)曲")
                    .font(.caption)
            }
            Spacer()
        }.padding(.all)
            
    }
}

struct song_cell: View {
    let song: Song2
    let machine: String
    @State var showSafari = false
    @State var urlString: String

    var body: some View{
        HStack{
            VStack(alignment: .leading){
                Text(song.name)
                Text(song.artist)
                    .font(.caption)
            }
            Spacer()
            if song.label == "なし"{
                Button(action: {
                    print(self.urlString)
                    showSafari.toggle()
                }) {
                    Text(song.label)
                }
            }else{
                #if os(iOS)
                if UIApplication.shared.canOpenURL(URL(string: "xgi-js-spnavi://")!) && navi_available(machine: machine){
                    Menu(content: {
                        Button(action: {
                            showSafari.toggle()
                        }, label: {
                            Text("JOYSOUND.bizで見る")
                        })
                            Link("キョクナビで開く", destination: URL(string: "xgi-js-spnavi://navigation?slc=\(song.label)&view=songDetails")!)
                        }
                    , label: {
                        Text(song.label)
                    })
                }else{
                    Button(action: {
                        print(self.urlString)
                        showSafari.toggle()
                    }) {
                        Text(song.label)
                    }
                }
                #else
                Button(action: {
                    print(self.urlString)
                    showSafari.toggle()
                }) {
                    Text(song.label)
                }
                #endif
            }
        }
        .padding(.all)
        .safariView(isPresented: $showSafari, content: {
            SafariView(url: URL(string: urlString)!, configuration: SafariView.Configuration(entersReaderIfAvailable: false, barCollapsingEnabled: true))
            .dismissButtonStyle(.done)
        })
        .onAppear{
            print(machine)
            print(navi_available(machine: machine))
        }
    }
}

struct playing_view: View{
    @Binding var playing: Song2
    @Binding var machine: String
    @Binding var showPlaying: Bool
    @Binding var offset: CGFloat
    @Binding var player_time: Double
    
    var body: some View{
        GeometryReader{g in
            VStack(spacing: 0){
                if playing.id != ""{
                    Spacer()
                    HStack(spacing: 0){
                        ZStack{
                            Rectangle()
                                .frame(height: 50)
                                .foregroundColor(Color("background"))
                            VStack{
                                ProgressView(value: player_time)
                                    .accentColor(.green)
                                HStack{
                                    Text("再生中")
                                        .font(.caption)
                                    Spacer()
                                }
                                HStack{
                                    Text(playing.name)
                                        .lineLimit(1)
                                    Spacer()
                                    #if os(iOS)
                                    if UIApplication.shared.canOpenURL(URL(string: "xgi-js-spnavi://")!) && navi_available(machine: machine){
                                        if playing.label != "なし"{
                                            Link(playing.label, destination: URL(string: "xgi-js-spnavi://navigation?slc=\(playing.label)&view=songDetails")!)
                                        }else{
                                            Text(playing.label)
                                        }
                                    }else{
                                        Text(playing.label)
                                    }
                                    #else
                                    Text(playing.label)
                                    #endif
                                }
                            }
                            .padding(.horizontal)
                        }
                        Button(action: {
                                print("Push")
                                if self.offset < 0{
                                    self.offset = 0
                                }else{
                                    self.offset = -g.size.width + 30
                                }
                        }, label: {
                            Image(systemName: "line.horizontal.3")
                                .frame(width: 30, height: 30)
                                .foregroundColor(Color("label"))
                                .background(Color("background"))
                                .cornerRadius(5)
                                .offset(x: -5)
                                .opacity(0.75)
                        })
                    }
                }
            }
            .offset(x: self.offset)
            .gesture(DragGesture()
                        .onChanged{ value in
                            if self.offset <= 0{
                                self.offset = value.translation.width
                            }
                        }
                        .onEnded{ value in
                            if value.location.x < value.startLocation.x{
                                if self.offset < -(g.size.width / 4){
                                    self.offset = -g.size.width + 30
                                }else{
                                    self.offset = 0
                                }
                            }else{
                                self.offset = 0
                            }
                        }
            )
        }
        .animation(.interactiveSpring())
    }
}

struct NavigationLink_Previews: PreviewProvider {
    static var previews: some View {
        playlist_cell(playlist: Playlist2(id: "test", name: "Playlist Name", songs: [], total: 0))
        song_cell(song: Song2(id: "id", name: "Song name", artist: "Song artist", label: "なし"), machine: "N", urlString: "")
    }
}
