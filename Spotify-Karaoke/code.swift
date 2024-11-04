//
//  code.swift
//  Spotify-Karaoke
//
//  Created by takumi saito on 2021/01/23.
//

import SwiftUI
import AuthenticationServices
import Kanna
import Reachability

final class Network {

    static func isOnline() -> Bool {
        let reachability = try! Reachability()
        return reachability.connection != .unavailable
    }

}
    
class AuthPresentationContextProver: NSObject, ASWebAuthenticationPresentationContextProviding {
    typealias ASPresentationAnchor = UIWindow

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

struct SpotifyToken: Codable{
    let access_token: String
    let expires_in: Int
    let scope: String
    let token_type: String
    let refresh_token: String
}

struct SpotifyRefreshToken: Codable{
    let access_token: String
    let expires_in: Int
    let scope: String
    let token_type: String
}

struct SpotifyAccount: Codable{
    let country: String
    let display_name: String
    let explicit_content: [String:Bool]
    let external_urls: [String:String]
    let followers: [String:Int]
    let href: String
    let id: String
    let images: [String]
    let product: String
    let type: String
    let uri: String
}

func get_token(client_id: String, client_secret: String, access_code: String, redirect_uri: String) -> String{
    print(access_code)
    let url = URL(string: "https://accounts.spotify.com/api/token")!
    var request = URLRequest(url: url)
    let auth_inside = "\(client_id):\(client_secret)"
    let auth = "Basic \(auth_inside.data(using: .utf8)!.base64EncodedString())"
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(auth, forHTTPHeaderField: "Authorization")
    let postString = "grant_type=authorization_code&code=\(access_code)&redirect_uri=\(redirect_uri)"
    request.httpBody = postString.data(using: String.Encoding.utf8)
    let condition = NSCondition()
    var result = ""
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in  //非同期で通信を行う
        guard let data = data else { return }
        condition.lock()
        do {
            print(String(data: data, encoding: .utf8)!)
            let object = try JSONDecoder().decode(SpotifyToken.self, from: data)
            result = object.access_token
            UserDefaults.standard.set(object.refresh_token, forKey: "refresh_token")
        } catch {
            result = "error"
        }
        condition.signal()
        condition.unlock()
    }
    condition.lock()
    task.resume()
    condition.wait()
    condition.unlock()
    return result
}

func get_new_token(client_id: String, client_secret: String, refresh_token: String) -> String{
    let url = URL(string: "https://accounts.spotify.com/api/token")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let auth_inside = "\(client_id):\(client_secret)"
    let auth = "Basic \(auth_inside.data(using: .utf8)!.base64EncodedString())"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(auth, forHTTPHeaderField: "Authorization")
    let postString = "grant_type=refresh_token&refresh_token=\(refresh_token)"
    request.httpBody = postString.data(using: String.Encoding.utf8)
    let condition = NSCondition()
    var result = ""
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in  //非同期で通信を行う
        guard let data = data else { return }
        condition.lock()
        do {
            print(String(data: data, encoding: .utf8)!)
            let object = try JSONDecoder().decode(SpotifyRefreshToken.self, from: data)
            result = object.access_token
        } catch {
            result = "error"
        }
        condition.signal()
        condition.unlock()
    }
    condition.lock()
    task.resume()
    condition.wait()
    condition.unlock()
    return result
}

func get_user_name(access_token: String) -> String{
    let url = URL(string: "https://api.spotify.com/v1/me?access_token=\(access_token)")!
    var result = ""
    do{
        let source = try String(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: source.data(using: .utf8)!, options: []) as? [String:Any]
        result = try json?["display_name"] as! String
    }catch{
        result = "error"
    }
    return result
}

func get_country(access_token: String) -> String{
    let url2 = URL(string: "https://api.spotify.com/v1/me?access_token=\(access_token)")!
    var country = ""
    do{
        let source = try String(contentsOf: url2)
        let json = try JSONSerialization.jsonObject(with: source.data(using: .utf8)!, options: []) as? [String:Any]
        country = json?["country"] as! String
    }catch{
        country = ""
    }
    return country
}

func get_playlist(access_token: String) -> [Playlist]{
    var all_playlists: [Playlist] = []
    let url = URL(string: "https://api.spotify.com/v1/me/playlists?access_token=\(access_token)")!
    var result: [[String:Any]] = []
    do{
        let source = try String(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: source.data(using: .utf8)!, options: []) as? [String:Any]
        result = json?["items"] as! [[String:Any]]
    }catch{
        result = []
    }
    let country = get_country(access_token: access_token)
    for playlist in result{
        let id = playlist["id"] as! String
        let name = playlist["name"] as! String
        let tracks = playlist["tracks"] as! [String: Any]
        let total = tracks["total"] as! Int
        var playlist_songs:[Song] = []
        for i in 0..<Int(ceil(Double(total)/100.0)){
            let playlist_url = URL(string: "https://api.spotify.com/v1/playlists/\(id)/tracks?market=\(country)&access_token=\(access_token)&offset=\(i*100)")!
            var songs: [[String:Any]]
            do{
                let source = try String(contentsOf: playlist_url)
                let json = try JSONSerialization.jsonObject(with: source.data(using: .utf8)!, options: []) as? [String:Any]
                songs = json?["items"] as! [[String:Any]]
            }catch{
                songs = []
            }
            for song in songs{
                let track = song["track"] as! [String: Any]
                let artists = track["artists"] as! [[String:Any]]
                var artist = artists[0]["name"] as! String
                if artists.count > 1{
                    for i in 1..<artists.count{
                        artist += "," + (artists[i]["name"] as! String)
                    }
                }
                let name = track["name"] as! String
                if let song_id = track["id"] as? String{
                    playlist_songs.append(Song(id: song_id, name: name, artist: artist))
                }
            }
        }
        all_playlists.append(Playlist(id: id, name: name, songs: playlist_songs, total: total))
    }
    return all_playlists
}

func get_favorite(access_token: String) -> Playlist{
    var songs: [Song] = []
    var total: Int = 0
    let url = URL(string: "https://api.spotify.com/v1/me/tracks?access_token=\(access_token)")!
    var result: [[String:Any]] = []
    do{
        let source = try String(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: source.data(using: .utf8)!, options: []) as? [String:Any]
        result = json?["items"] as! [[String:Any]]
        total = json?["total"] as! Int
    }catch{
        result = []
    }
    for song in result{
        let track = song["track"] as! [String: Any]
        let id = track["id"] as! String
        let artists = track["artists"] as! [[String:Any]]
        var artist = artists[0]["name"] as! String
        if artists.count > 1{
            for i in 1..<artists.count{
                artist += "," + (artists[i]["name"] as! String)
            }
        }
        let name = track["name"] as! String
        songs.append(Song(id: id, name: name, artist: artist))
    }
    for i in 1..<Int(ceil(Double(total)/20.0)){
        let url = URL(string: "https://api.spotify.com/v1/me/tracks?access_token=\(access_token)&offset=\(20*i)&limit=20")!
        var result: [[String:Any]] = []
        do{
            let source = try String(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: source.data(using: .utf8)!, options: []) as? [String:Any]
            result = json?["items"] as! [[String:Any]]
        }catch{
            result = []
        }
        for song in result{
            let track = song["track"] as! [String: Any]
            let id = track["id"] as! String
            let artists = track["artists"] as! [[String:Any]]
            var artist = artists[0]["name"] as! String
            if artists.count > 1{
                for i in 1..<artists.count{
                    artist += "," + (artists[i]["name"] as! String)
                }
            }
            let name = track["name"] as! String
            songs.append(Song(id: id, name: name, artist: artist))
        }
    }
    return Playlist(id: "favorite", name: "お気に入りの曲", songs: songs, total: total)
}

func get_playing(access_token: String, machine: String, playing_status: Binding<Double>) -> Song2{
    let country = get_country(access_token: access_token)
    let url = URL(string: "https://api.spotify.com/v1/me/player/currently-playing?market=\(country)&access_token=\(access_token)")!
    do{
        let source = try String(contentsOf: url)
        if source == ""{
            return Song2(id: "", name: "", artist: "", label: "")
        }else{
            let json = try JSONSerialization.jsonObject(with: source.data(using: .utf8)!, options: []) as? [String:Any]
            let item = try json?["item"] as! [String: Any]
            let artists = item["artists"] as! [[String:Any]]
            var artist = artists[0]["name"] as! String
            if artists.count > 1{
                for i in 1..<artists.count{
                    artist += "," + (artists[i]["name"] as! String)
                }
            }
            let name = item["name"] as! String
            let id = item["id"] as! String
            playing_status.wrappedValue = Double(json?["progress_ms"] as! Int) / Double(item["duration_ms"] as! Int)
            return Conv_Song_to_Song2(song: [Song(id: id, name: name, artist: artist)], machine: machine)[0]
        }
    }catch{
        return Song2(id: "", name: "", artist: "", label: "")
    }
}

struct Song: Identifiable{
    var id: String
    var name: String
    var artist: String
}

struct Song2: Identifiable{
    var id: String
    var name: String
    var artist: String
    var label: String
}

struct Playlist: Identifiable{
    var id: String
    var name: String
    var songs: [Song]
    var total: Int
}

struct Playlist2: Identifiable{
    var id: String
    var name: String
    var songs: [Song2]
    var total: Int
}

func getSongNum(name: String, artist: String, machine: String) -> String{
    let url_str = "https://joysound.biz/search/song.php?machine=\(machine)&word=\(name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)&matchs=1"
    let url = URL(string: url_str)!
    let artists = artist.components(separatedBy: ",")
    do{
        let doc = try HTML(url: url, encoding: .utf8)
        let songs = doc.css(".tableList tbody tr")
        for i in 0..<songs.count{
            let song_name = songs[i].css(".r2 a")[0].text!
            let song_artist = songs[i].css(".r3 a")[0].text!
            if songs.count > 1{
                var artist_contain = false
                for artist in artists{
                    artist_contain = song_artist.contains(artist) || artist_contain
                }
                if song_name == name && artist_contain{
                    return songs[i].css(".r4")[0].text!
                }
            }else{
                if song_name == name{
                    return songs[i].css(".r4")[0].text!
                }
            }
        }
    }catch{
        return "なし"
    }
    return "なし"
}

func load_machines() -> NSDictionary{
    let path = Bundle.main.path(forResource: "joysound-biz", ofType: "plist")
    return NSDictionary(contentsOfFile: path!)!["name"] as! NSDictionary
}

func navi_available(machine: String) -> Bool{
    let path = Bundle.main.path(forResource: "joysound-biz", ofType: "plist")
    return (NSDictionary(contentsOfFile: path!)!["navi"] as! NSDictionary)[machine] as! Bool
}

func Conv_Song_to_Song2(song: [Song], machine: String) -> [Song2]{
    var data: NSMutableDictionary = [:]
    var data_all: NSMutableDictionary = [:]
    let manager = FileManager.default
    let documentDir = manager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let url = documentDir.appendingPathComponent("main.plist")
    if manager.fileExists(atPath: url.path){
        data_all = NSMutableDictionary(contentsOfFile: url.path)!
    }
    if data_all[machine] != nil{
        data = data_all[machine] as! NSMutableDictionary
    }
    var new_songs:[Song2] = []
    for sg in song{
        if data[sg.id] != nil{
            new_songs.append(Song2(id: sg.id, name: sg.name, artist: sg.artist, label: data[sg.id] as! String))
        }else{
            let label = getSongNum(name: sg.name, artist: sg.artist, machine: machine)
            data.setValue(label, forKey: sg.id)
            new_songs.append(Song2(id: sg.id, name: sg.name, artist: sg.artist, label: label))
        }
    }
    data_all[machine] = data
    data_all.write(to: url, atomically: true)
    return new_songs
}
