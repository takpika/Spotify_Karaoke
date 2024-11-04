//
//  ContentView.swift
//  Spotify-Karaoke
//
//  Created by takumi saito on 2021/01/23.
//

import SwiftUI
import AuthenticationServices

struct ContentView: View {
    let client_id = "SPOTIFY_CLIENT_ID"
    let client_secret = "SPOTIFY_CLIENT_SECRET"
    let redirect_uri = "sp-kr://callback".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var account_text = "ログイン"
    @State var access_code: String = ""
    @State var access_token: String = ""
    @State var data:[Playlist] = []
    @State var data2: [Playlist2] = []
    @State var refreshing_text = "test"
    @State var machines: NSDictionary = [:]
    @State var selectedmachine = 0
    @State var is_refreshing = false
    @State var progress = 0.0
    @State var logined = true
    @State var playing: Song2 = Song2(id: "", name: "", artist: "", label: "")
    @State var machine = "N"
    @State var showPlaying = true
    @State var offset: CGFloat = CGFloat.zero
    @State var player_time: Double = 0
    /*
    init(){
        if UserDefaults.standard.object(forKey: "access_code") == nil{
            self.account_text = "ログイン"
            self.access_code = ""
            self.data = []
        }else{
            access_code = UserDefaults.standard.object(forKey: "access_code") as! String
            print(access_code)
            if self.access_code != ""{
                self.access_token = get_token(client_id: self.client_id, client_secret: self.client_secret, access_code: self.access_code, redirect_uri: self.redirect_uri)
                self.account_text = get_user_name(access_token: self.access_token)
                self.data = get_playlist(access_token: self.access_token)
            }else{
                self.account_text = "ログイン"
                self.access_code = ""
                self.data = []
            }
        }
    }
    */
    
    var body: some View {
        NavigationView{
            ZStack{
                List(data2){ playlist in
                    NavigationLink(destination: SongList(songs: playlist.songs, name: playlist.name, machine: machines.allKeys[selectedmachine] as! String, playing: $playing, showPlaying: $showPlaying, offset: $offset, player_time: $player_time)){
                        playlist_cell(playlist: playlist)
                    }
                }
                .animation(.default)
                .disabled(is_refreshing)
                playing_view(playing: $playing, machine: $machine, showPlaying: $showPlaying, offset: $offset, player_time: $player_time)
                VStack{
                    Spacer()
                    if is_refreshing{
                        ProgressView(value: progress)
                            .animation(.interactiveSpring())
                    }
                }
            }
            .navigationTitle("ライブラリ")
            .navigationBarItems(
                leading: SelectMachineMenu(refreshing_text: $refreshing_text, machines: $machines, selectedmachine: $selectedmachine, data: $data, data2: $data2, is_refreshing: $is_refreshing, logined: $logined, machine: $machine),
                trailing: Account_Button(client_id: client_id, client_secret: client_secret, redirect_uri: redirect_uri, access_code: $access_code, access_token: $access_token, account_text: $account_text, data: $data, data2: $data2, refreshing_text: $refreshing_text, machines: $machines, selectedmachine: $selectedmachine, is_refreshing: $is_refreshing, progress: $progress, logined: $logined)
            )
            .onReceive(timer, perform: { _ in
                if access_token != ""{
                    playing = get_playing(access_token: access_token, machine: machines.allKeys[selectedmachine] as! String, playing_status: $player_time)
                }
            })
            .onAppear {
                self.machines = load_machines()
                if UserDefaults.standard.object(forKey: "selectedmachine") != nil{
                    selectedmachine = UserDefaults.standard.object(forKey: "selectedmachine") as! Int
                }
                machine = machines.allKeys[selectedmachine] as! String
                self.refreshing_text = machines[machines.allKeys[selectedmachine] as! String] as! String
                print(self.refreshing_text)
                if self.access_token == ""{
                    if UserDefaults.standard.object(forKey: "refresh_token") == nil{
                        self.account_text = "ログイン"
                        self.access_token = ""
                        self.data = []
                    }else{
                        let refresh_token = UserDefaults.standard.object(forKey: "refresh_token") as! String
                        if refresh_token != ""{
                            logined = false
                            self.access_token = get_new_token(client_id: self.client_id, client_secret: self.client_secret, refresh_token: refresh_token)
                            print(self.access_token)
                            self.account_text = get_user_name(access_token: self.access_token)
                            if self.account_text != "error"{
                                self.data = get_playlist(access_token: self.access_token)
                                self.data.insert(get_favorite(access_token: self.access_token), at: 0)
                                let queue = DispatchQueue(label: "refresh_data", qos: .userInteractive)
                                queue.async {
                                    self.refreshing_text = "更新中です"
                                    print(machines.allKeys[selectedmachine] as! String)
                                    data2 = []
                                    is_refreshing = true
                                    progress = 0.0
                                    var count = 0
                                    var processed = 0
                                    for playlist in self.data{
                                        count += playlist.total
                                    }
                                    for playlist in self.data{
                                        data2.append(Playlist2(id: playlist.id, name: playlist.name, songs: Conv_Song_to_Song2(song: playlist.songs, machine: machines.allKeys[selectedmachine] as! String), total: playlist.total))
                                        processed += playlist.total
                                        progress = Double(processed)/Double(count)
                                    }
                                    is_refreshing = false
                                    self.refreshing_text = machines[machines.allKeys[selectedmachine] as! String] as! String
                                }
                            }else{
                                self.account_text = "ログイン"
                                self.access_token = ""
                                self.data = []
                            }
                        }else{
                            self.account_text = "ログイン"
                            self.access_token = ""
                            self.data = []
                        }
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Account_Button: View{
    let client_id: String
    let client_secret: String
    let redirect_uri: String
    @Binding var access_code: String
    @Binding var access_token: String
    @Binding var account_text: String
    @Binding var data: [Playlist]
    @Binding var data2: [Playlist2]
    @Binding var refreshing_text: String
    @Binding var machines: NSDictionary
    @Binding var selectedmachine: Int
    @Binding var is_refreshing: Bool
    @Binding var progress: Double
    @Binding var logined: Bool
    var body: some View{
        if access_token == ""{
            Button(
                action: {
                    login_Spotify()
                },
                label: {
                    Text(account_text)
                }
            )
        }else{
            Menu(account_text){
                Button(action: {
                    access_token = ""
                    account_text = "ログイン"
                    data2 = []
                    UserDefaults.standard.set(nil, forKey: "refresh_token")
                }, label: {
                    Text("ログアウト")
                    Image(systemName: "arrow.down.left.circle.fill")
                })
            }
            .disabled(is_refreshing)
        }
    }
    func login_Spotify(){
        var session: ASWebAuthenticationSession?
        let response_type = "code"
        let scope = "user-read-currently-playing playlist-read-private playlist-read-collaborative user-library-read user-read-private".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let url = URL(string: "https://accounts.spotify.com/authorize?client_id=\(client_id)&response_type=\(response_type)&redirect_uri=\(redirect_uri)&scope=\(scope)")!
        session = ASWebAuthenticationSession(url: url, callbackURLScheme: nil) { url, error in
            if let error = error {
                print(error)
            } else if let url = url {
                let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
                if urlComponents?.queryItems?.first?.name == "code"{
                    logined = false
                    access_code = (urlComponents?.queryItems?.first?.value)!
                    access_token = get_token(client_id: client_id, client_secret: client_secret, access_code: access_code, redirect_uri: redirect_uri)
                    account_text = get_user_name(access_token: access_token)
                    data = get_playlist(access_token: access_token)
                    data.insert(get_favorite(access_token: self.access_token), at: 0)
                    let queue = DispatchQueue(label: "refresh_data", qos: .userInteractive)
                    queue.async {
                        self.refreshing_text = "更新中です"
                        print(machines.allKeys[selectedmachine] as! String)
                        data2 = []
                        is_refreshing = true
                        var count = 0
                        var processed = 0
                        for playlist in self.data{
                            count += playlist.total
                        }
                        progress = 0.0
                        for playlist in self.data{
                            data2.append(Playlist2(id: playlist.id, name: playlist.name, songs: Conv_Song_to_Song2(song: playlist.songs, machine: machines.allKeys[selectedmachine] as! String), total: playlist.total))
                            processed += playlist.total
                            progress = Double(processed)/Double(count)
                        }
                        is_refreshing = false
                        self.refreshing_text = machines[machines.allKeys[selectedmachine] as! String] as! String
                    }
                }
            }
        }
        let presentationContextProvider = AuthPresentationContextProver()
        session?.presentationContextProvider = presentationContextProvider
        session?.prefersEphemeralWebBrowserSession = true
        session?.start()
    }
}

struct SelectMachineMenu: View{
    @Binding var refreshing_text: String
    @Binding var machines: NSDictionary
    @Binding var selectedmachine: Int
    @Binding var data: [Playlist]
    @Binding var data2: [Playlist2]
    @Binding var is_refreshing: Bool
    @Binding var logined: Bool
    @Binding var machine: String
    
    var body: some View{
        Menu(refreshing_text){
            Picker(selection: $selectedmachine, label: Text("JOYSOUND Machine"), content: {
                ForEach(0..<machines.count){
                    Text(machines[machines.allKeys[$0] as! String] as! String)
                }
            })
            .onChange(of: selectedmachine){i in
                UserDefaults.standard.setValue(i, forKey: "selectedmachine")
                let queue = DispatchQueue(label: "refresh_data", qos: .userInteractive)
                machine = machines.allKeys[selectedmachine] as! String
                queue.async {
                    self.refreshing_text = "更新中です"
                    print(machines.allKeys[i] as! String)
                    data2 = []
                    is_refreshing = true
                    for playlist in self.data{
                        data2.append(Playlist2(id: playlist.id, name: playlist.name, songs: Conv_Song_to_Song2(song: playlist.songs, machine: machines.allKeys[selectedmachine] as! String), total: playlist.total))
                    }
                    is_refreshing = false
                    self.refreshing_text = machines[machines.allKeys[i] as! String] as! String
                }
            }
            .popover(isPresented: $logined) {
                VStack{
                    Text("ログインする前に…")
                        .font(.subheadline)
                    Text("ログインする前に、使用機材を選んでください！")
                }
            }
        }
        .disabled(is_refreshing)
    }
}
