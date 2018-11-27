//
//  MoviesTableViewController.swift
//  NaverAPIExample
//
//  Created by MBP04 on 2018. 4. 5..
//  Copyright © 2018년 codershigh. All rights reserved.
//

import UIKit
import os.log
import SafariServices

class MoviesTableViewController: UITableViewController, XMLParserDelegate{
   	 @IBOutlet weak var titleNavigationItem: UINavigationItem!
    
    let posterImageQueue = DispatchQueue(label: "posterImage")
    
    let clientID        = "75mkVPNFOQVf1jFmHi5F"    // ClientID
    let clientSecret    = "Gsy2Q8EJ3_"              // ClientSecret
    
    var queryText:String?                   // SearchVC에서 받아 오는 검색어
    var movies:[Movie]              = []    // API를 통해 받아온 결과를 저장할 array
    
    // XML delegate
    var strXMLData: String?         = ""   // xml 데이터를 저장
    var currentTag: String?         = ""   // 현재 item의 tag를 저장
    var currentElement: String      = ""   // 현재 element의 내용을 저장
    var item: Movie?                = nil  // 검색하여 만들어지는 Movie 객체
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let title = queryText {
            titleNavigationItem.title = title
        }
        searchMovies()
        print("print item : \(item as Any)")
    }

    // MARK: - NaverAPI
    
    func searchMovies() {
        // movies 초기화
        movies = []
        
        // queryText가 없으면 return
        guard let query = queryText else {
         
            return
        }
        
        let urlString = "https://openapi.naver.com/v1/search/local.xml?query=" + query
        let urlWithPercentEscapes = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: urlWithPercentEscapes!)
        
        var request = URLRequest(url: url!)
        request.addValue("application/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(clientID, forHTTPHeaderField: "X-Naver-Client-Id")
        request.addValue(clientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // 에러가 있으면 리턴
            guard error == nil else {
                print(error as Any)
                print("task error")
                   print(data as Any)	// as Any는 지워도 됩니다!
                return
            }
            
            
             //데이터 반환값 확인용
            if let data = data
            {
                let data = String(data: data, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) ?? ""
                print(data);
            }
            
            //let str = String(data: data, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) ?? ""
            // 데이터가 비었으면 출력 후 리턴
            guard let data = data else {
                print("Data is empty")
                return
            }
            
            //print("respone : \(response) first \n")
            //print("request : \(request) second \n")
            //print("Data(data) : \(Data(data)) \n")
            //print("\n")
            
            //print(response)
            //print("test\n")
            // 데이터 초기화
            self.item?.actors = ""
            self.item?.director = ""
            self.item?.imageURL = ""
            self.item?.link = ""//음식점 중에 링크가 없는 경욱 많음
            self.item?.pubDate = ""
            self.item?.title = ""
            self.item?.userRating = ""
            
            self.item?.description = ""
            self.item?.telephone = ""
            self.item?.address = ""
            self.item?.roadAddress = ""
            self.item?.mapx = nil
            self.item?.mapy = nil
            
            //	print(data)
            //print("test2222\n")
            
            // Parse the XML
            let parser = XMLParser(data: Data(data))
            parser.delegate = self
            let success:Bool = parser.parse()
            if success {
                print("파서 성공시 출력 : \(self.strXMLData as Any)") // as Any는 지워도 됩니다!
            } else {
                print("parse failure!")
            }
        }
        task.resume()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "title" || elementName == "link" || elementName == "image" || elementName == "pubDate" || elementName == "director" || elementName == "actor" || elementName == "userRating" || elementName == "mapx" || elementName == "mapy" || elementName == "address" || elementName == "roadAddress" {
            currentElement = ""
            if elementName == "title" {
                item = Movie()
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentElement += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "title" {
            item?.title = currentElement.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        } else if elementName == "link" {
            item?.link = currentElement
        } else if elementName == "image" {
            item?.imageURL = currentElement
        } else if elementName == "pubDate" {
            item?.pubDate = currentElement
        } else if elementName == "director" {
            item?.director = currentElement
            if item?.director != "" {
                item?.director?.removeLast()
            }
        } else if elementName == "actor" {
            item?.actors = currentElement
            if item?.actors != "" {
                item?.actors?.removeLast()
            }
        } else if elementName == "userRating" {
            item?.userRating = currentElement
            movies.append(self.item!)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
            
        
        else if elementName == "address" {
            item?.address = currentElement
           // item?.actors = currentElement
        }
        
        else if elementName == "telephone" {
            item?.telephone = currentElement
        }
        
        
        else if elementName == "roadAddress" {
            item?.roadAddress = currentElement
        }
        
        else if elementName == "mapx" {
            item?.mapx = Int(currentElement)
        }
        else if elementName == "mapy" {
            item?.mapy = Int(currentElement)
        }
 
        print("상호명 : \(String(describing: item!.title))   주소 : \(item!.address) x좌표 : \(item!.mapx) y좌표 : \(item!.mapy) 링크 : \(item!.link)")
        //print("영화명 : \(item!.title)   감독 : \(item!.director)")
       
    }
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }

    //여기부터 더 파악할것
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "movieCellIdentifier", for: indexPath) as! MoviesTableViewCell
        let movie = movies[indexPath.row]
       
        //영화. UI에 삽입 제대로 동작함
        /*
        guard let title = movie.title, let pubDate = movie.pubDate, let userRating = movie.userRating, let director = movie.director, let actor = movie.actors else {
            return cell
        }
 
        */
        
        //지역. UI에 삽입 미동작
        /*
        guard let title = movie.title, let address = movie.address, let roadAddress = movie.roadAddress, let mapx = movie.mapx, let mapy = movie.mapy, let telephone = movie.telephone else {
            return cell
        }
        */
        
        
        //영화 + 지역. 삽입 미동작
        /*
        guard let title = movie.title, let pubDate = movie.pubDate, let userRating = movie.userRating, let director = movie.director, let actor = movie.actors, let address = movie.address, let roadAddress = movie.roadAddress, let mapx = movie.mapx, let mapy = movie.mapy, let telephone = movie.telephone else {
            return cell
        }
        */
        
        //만약에 동작할 경우 미사용 변수는 제거해야지 제대로 UI에 삽입된다는 것임
        guard let title = movie.title, let address = movie.address, let telephone = movie.telephone else {
            return cell
        }
        /*
         @IBOutlet weak var titleAndYearLabel: UILabel!
         @IBOutlet weak var posterImageView: UIImageView!
         @IBOutlet weak var userRatingLabel: UILabel!
         @IBOutlet weak var directorLabel: UILabel!
         @IBOutlet weak var actorsLabel: UILabel!
        */
        // 제목 및 개봉년도 레이블
        
        /*
         cell.titleAndYearLabel.text = "\(title)(\(pubDate))"
         cell.userRatingLabel.text = "\(userRating)"
         cell.directorLabel.text = "\(director)"
         cell.actorsLabel.text = "\(actor)"
         */
        // 평점 레이블
        
        /*
        if userRating == "0.00" {
            cell.userRatingLabel.text = "정보 없음"
        } else {
            cell.userRatingLabel.text = "\(userRating)"
            //cell.userRatingLabel.text = "\(mapx)"
        }
        // 감독 레이블
        
        if director == "" {
            cell.directorLabel.text = "정보 없음"
        } else {
            cell.directorLabel.text = "\(director)"
            //cell.directorLabel.text = "\(telephone)"
        }
        // 출연 배우 레이블
        
         if actor == "" {
         cell.actorsLabel.text = "정보 없음"
         } else {
         cell.actorsLabel.text = "\(actor)"
         // cell.actorsLabel.text = "\(address)"
         }
         */
        
        
        cell.titleAndYearLabel.text = "\(title)"
        cell.actorsLabel.text = "\(address)"
        cell.directorLabel.text = "\(telephone)"
        cell.userRatingLabel.text = "0.00"
 
        
        /*
        // 좌표 레이블
        if mapx == nil {
            cell.userRatingLabel.text = "정보 없음"
        } else {
            //cell.userRatingLabel.text = "\(userRating)"
            cell.userRatingLabel.text = "\(mapx),\(mapy)"
        }
        
        
         
        
        // 감독=>전화번호 레이블
        if telephone == "" {
            cell.directorLabel.text = "정보 없음"
        } else {
            //cell.directorLabel.text = "\(director)"
            cell.directorLabel.text = "\(telephone)"
        }
        
        
     
        
        // 출연 배우 레이블 => 주소 레이블
        if address == ""	{
            cell.actorsLabel.text = "정보 없음"
        } else {
           // cell.actorsLabel.text = "\(actor)"
             cell.actorsLabel.text = "\(address)"
        }
        */
        
        // Async activity
        // 영화 포스터 이미지 불러오기
        /*
        if let posterImage = movie.image {
            cell.posterImageView.image = posterImage
        } else {
            cell.posterImageView.image = UIImage(named: "noImage")
            posterImageQueue.async(execute: {
                movie.getPosterImage()
                guard let thumbImage = movie.image else {
                    return
                }
                DispatchQueue.main.async {
                    cell.posterImageView.image = thumbImage
                }
            })
        }
        */
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let urlString = movies[indexPath.row].link {
            if let url = URL(string: urlString) {
                let svc = SFSafariViewController(url: url)
                self.present(svc, animated: true, completion: nil)
            }
        }
    }
    
}

