//
//  ListViewController.swift
//  MyMovieChart
//
//  Created by SeungYeon Yoo on 2022/05/28.
//

import UIKit
class ListViewController: UITableViewController {
    //현재까지 읽어온 데이터의 페이지 정보
    var page = 1
    
    //테이블 뷰를 구성할 리스트 데이터
    lazy var list: [MovieVO] = {
        var datalist = [MovieVO]()
        return datalist
    }()
    
    @IBOutlet var moreBtn: UIButton!
    
    //더보기 버튼을 눌렀을 때 호출되는 메소드
    @IBAction func more(_ sender: Any) {
        //현재 페이지 값에 1을 추가한다.
        self.page += 1
        //영화차트 API를 호출한다.
        self.callMovieAPI()
        //데이터를 다시 읽어오도록 테이블뷰를 갱신한다.
        self.tableView.reloadData()
    }
        //뷰가 처음 메모리에 로드될 때 호출되는 메소드
        override func viewDidLoad() {
        //영화 차트 API를 호출한다.
        self.callMovieAPI()
    }
    
    //영화 차트 API를 호출해주는 메소드
    func callMovieAPI(){
        
        //1)호핀 API호출을 위한 URI를 생성
        let url = "http://swiftapi.rubypaper.co.kr:2029/hoppin/movies?version=1&page=\(self.page)&count=30&genreId=&order=releasedateas"
        let apiURI: URL! = URL(string: url)
        
        //2)REST API를 호출
        let apidata = try! Data(contentsOf: apiURI)
        
        //3)데이터 전송 결과를 로그로 출력 (반드시 필요한 코드는 아님)
        let log = NSString(data: apidata, encoding: String.Encoding.utf8.rawValue) ?? ""
        NSLog("API Result=\(log)")
        
        //4)JSON객체를 파싱하여 NSDictionary 객체로 변환
        do {
            let apiDictionary = try JSONSerialization.jsonObject(with: apidata, options:[])
            as! NSDictionary
            
        //5)데이터 구조에 따라 차례대로 캐스팅하며 읽어온다.
        let hoppin = apiDictionary["hoppin"] as! NSDictionary
        let movies = hoppin["movies"] as! NSDictionary
        let movie = movies["movie"] as! NSArray
            
        //6) Iterator 처리를 하면서 API데이터를 MovieVO 객체에 저장.
        for row in movie {
            //순회 상수를 NSDictionary타입으로 캐스팅
            let r = row as! NSDictionary
            
            //테이블뷰 리스트를 구성할 데이터 형식
            let mvo = MovieVO()
            
            //movie 배열의 각 데이터를 mvo상수의 속성에 대입
            mvo.title = r["title"] as? String
            mvo.description = r["genreNames"] as? String
            mvo.thumbnail = r["thumbnailImage"] as? String
            mvo.detail = r["linkUrl"] as? String
            mvo.rating = ((r["ratingAverage"] as! NSString).doubleValue)
            
            //웹상에 있는 이미지를 읽어와 UIImage객체로 생성
            let url: URL! = URL(string: mvo.thumbnail!)
            let imageData = try! Data(contentsOf: url)
            mvo.thumbnailImage = UIImage(data: imageData)
            
            //list배열에 추가
            self.list.append(mvo)
                
            //7)전체 데이터 카운트를 얻는다.
            let totalCount = (hoppin["totalCount"] as? NSString)!.integerValue
                
            //8)totalCount가 읽어온 데이터 크기와 같거나 클 경우 더보기 버튼을 막는다.
            if (self.list.count >= totalCount) {
                self.moreBtn.isHidden = true
            }
        }
    } catch {
        NSLog("Parse Error!")
    }
}
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.list.count
    }
    
    func getThumbnailImage(_ index: Int) -> UIImage {
        //인자값으로 받은 인덱스를 기반으로 해당하는 배열 데이터를 읽어옴
        let mvo = self.list[index]
        
        //메모이제이션: 저장된 이미지가 있으면 그것을 반환하고, 없을 경우 내려받아 저장한 후 반환
        if let savedImage = mvo.thumbnailImage {
            return savedImage
        } else {
            let url: URL! = URL(string: mvo.thumbnail!)
            let imageData = try! Data(contentsOf: url)
            mvo.thumbnailImage = UIImage(data:imageData) //UIImage를 MovieVO객체에 우선 저장
            
            return mvo.thumbnailImage! //저장된 이미지를 반환
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //주어진 행에 맞는 데이터 소스를 읽어온다.
        let row = self.list[indexPath.row]
        
        //로그 출력
        NSLog("제목:\(row.title!), 호출된 행번호:\(indexPath.row)")
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListCell") as! MovieCell
        
        //데이터 소스에 저장된 값을 각 아울렛 변수에 할당
        cell.title?.text = row.title
        cell.desc?.text = row.description
        cell.opendate?.text = row.opendate
        cell.rating?.text = "\(row.rating!)"
        
       //비동기 방식으로 섬네일 이미지를 읽어옴
        DispatchQueue.main.async(execute: {
            cell.thumbnail.image = self.getThumbnailImage(indexPath.row)
        })
        
        //셀 객체를 반환
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NSLog("선택된 행은 \(indexPath.row)번째 행입니다.")
    }
}

// MARK: - 화면 전환 시 값을 넘겨주기 위한 세그웨이 관련 처리
extension ListViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //실행된 세그웨이의 식별자가 "segue_detail"이라면
        if segue.identifier == "segue_detail" {
            //사용자가 클릭한 행을 찾아낸다.
            let path = self.tableView.indexPath(for: sender as! MovieCell)
            
            //행 정보를 통해 선택된 영화 데이터를 찾은 다음, 목적지 뷰 컨트롤러의 mvo변수에 대입한다.
            let detailVC = segue.destination as? DetailViewController
            detailVC?.mvo = self.list[path!.row]
        }
    }
}
