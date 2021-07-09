//
//  ViewController.swift
//  babyProject
//
//  Created by Otto Linden on 31.3.2021.
//

import UIKit
import Combine

struct GlobalValues {
    static var rootUrl = "https://api.turkuforge.fi"
    static var sockjsEndpoint: URL?
}

class ViewController: UIViewController {

    @IBOutlet weak var channelCollection: UICollectionView!

    private var cancellable: AnyCancellable?
    var _channels: [bpChannel]? = [bpChannel]()
    var channels: [bpChannel]? {
        get {
            return _channels
        } set {
            _channels = newValue
            DispatchQueue.main.async {
                self.channelCollection.reloadData()
            }
        }
    }
    var result: bpRootResponse?

    override func viewDidLoad() {
        super.viewDidLoad()
        preventLargeTitleCollapsing()

        let url = URL(string: GlobalValues.rootUrl)!
        self.cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: bpRootResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
            .sink(receiveCompletion: { _ in  },
                  receiveValue: { response in
                    self.channels = response.embedded.channelList
                    GlobalValues.sockjsEndpoint = response.links.sockJsEndpoint?.href
                  })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.sizeToFit()
    }

    private func preventLargeTitleCollapsing() {
        let dummyView = UIView()
        view.addSubview(dummyView)
        view.sendSubviewToBack(dummyView)
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return channels?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "channelCell", for: indexPath) as! ChannelCollectionViewCell
        let channel = channels?[indexPath.item]

        cell.channelNameLabel.text = channel?.name.capitalized ?? "failed"

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let channel = channels?[indexPath.item]
        let vc = ChannelViewController()
        vc.channel = channel
        vc.title = channel?.name.capitalized ?? ""
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = CGSize.zero
        let inset = collectionView.contentInset.left + collectionView.contentInset.right

        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            size = layout.itemSize
            size.width = collectionView.bounds.width - inset
        }
        return size
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        channelCollection.collectionViewLayout.invalidateLayout()
    }
}
