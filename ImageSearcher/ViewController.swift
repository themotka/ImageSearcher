//
//  ViewController.swift
//  ImageSearcher
//
//  Created by Matthew Widemann on 18.12.2024.
//

import UIKit

// MARK: - SearchViewController

final class ImageSearchViewController: UIViewController {
    
    // MARK: - Private Properties

    private let tableView = UITableView()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout.createFlowLayout(
            viewWidth: UIScreen.main.bounds.width,
            numberOfItemsInRow: 2,
            padding: 16,
            interItemSpacing: 16
        )
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    
    private let service = APIService()
    private var photos: [APIModel] = []
    private let historyManager = SearchHistoryManager()
    private var filteredHistory: [String] = []
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search images"
        return searchBar
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        setupViews()
        collectionView.register(
            ImageInstance.self,
            forCellWithReuseIdentifier: ImageInstance.reuseIdentifier
        )
        tableView.register(
            UITableViewCell.self, forCellReuseIdentifier: "historyCell"
        )
    }
    
    // MARK: - Private Methods
    
    private func setupViews() {
        view.backgroundColor = .white
        
        [searchBar, collectionView, tableView, activityIndicator].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        searchBar.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = true
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func error(message: String) {
        let alertController = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(
                title: "Ок",
                style: .default
            )
        )
        present(alertController, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension ImageSearchViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageInstance.reuseIdentifier, for: indexPath) as? ImageInstance else {
            return UICollectionViewCell()
        }
        let photo = photos[indexPath.item]
        cell.configure(with: photo)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension ImageSearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedPhoto = photos[indexPath.item]
        let detailVC = DetailViewController(photo: selectedPhoto)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UICollectionViewFlowLayout

extension UICollectionViewFlowLayout {
    
    static func createFlowLayout(viewWidth: CGFloat, numberOfItemsInRow: CGFloat, padding: CGFloat, interItemSpacing: CGFloat) -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        let totalPadding = padding * 2 + (numberOfItemsInRow - 1) * interItemSpacing
        let itemWidth = (viewWidth - totalPadding) / numberOfItemsInRow
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumInteritemSpacing = interItemSpacing
        layout.minimumLineSpacing = interItemSpacing
        layout.sectionInset = UIEdgeInsets(top: 16, left: padding, bottom: 16, right: padding)
        return layout
    }
}


// MARK: - UISearchBarDelegate

extension ImageSearchViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let history = historyManager.getHistory()
        filteredHistory = history.filter { $0.lowercased().contains(searchText.lowercased()) }
        tableView.isHidden = filteredHistory.isEmpty
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text else { return }
        historyManager.saveQuery(query)
        activityIndicator.startAnimating()
        service.searchPhotos(query: query) { result in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                switch result {
                case .success(let photos):
                    self.photos = photos
                    self.collectionView.reloadData()
                case .failure(let error):
                    self.error(message: "Не удалось загрузить данные: \(error.localizedDescription)")
                }
            }
        }
        tableView.isHidden = true
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension ImageSearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath)
        cell.textLabel?.text = filteredHistory[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedQuery = filteredHistory[indexPath.row]
        searchBar.text = selectedQuery
        searchBarSearchButtonClicked(searchBar)
    }
}



final class DetailViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private var photo: APIModel
    private var pinchGestureRecognizer: UIPinchGestureRecognizer!
    private var doubleTapGestureRecognizer: UITapGestureRecognizer!
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private lazy var authorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .light)
        label.textColor = .gray
        label.textAlignment = .left
        return label
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "square.and.arrow.up.circle"), for: .normal)
        button.setTitle("SHARE", for: .normal)
        button.addTarget(self, action: #selector(shareImage), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initializer
    
    init(photo: APIModel) {
        self.photo = photo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupData()
        setupGestures()
    }
    
    // MARK: - Action Methods
    
    @objc private func shareImage() {
        guard let image = imageView.image else { return }
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
    
    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard recognizer.state == .changed || recognizer.state == .ended else { return }
        imageView.transform = imageView.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
        recognizer.scale = 1.0
    }
    
    @objc private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.3) {
            self.imageView.transform = .identity
        }
    }
    
    // MARK: - Private Methods
    
    private func setupViews() {
        view.backgroundColor = .white
        
        [imageView,
         descriptionLabel,
         authorLabel,
         activityIndicator,
         shareButton
        ].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            authorLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            authorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            authorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupData() {
        descriptionLabel.text = photo.description ?? ""
        authorLabel.text = "Author: \(photo.user.name)"
        activityIndicator.startAnimating()
        if let url = URL(string: photo.urls.full) {
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    if let data = data, error == nil, let image = UIImage(data: data) {
                        self?.imageView.image = image
                    } else {
                        self?.imageView.image = UIImage(systemName: "xmark.octagon")
                    }
                }
            }
            task.resume()
        } else {
            activityIndicator.stopAnimating()
            imageView.image = UIImage(systemName: "xmark.octagon")
        }
    }
    
    private func setupGestures() {
        pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        imageView.addGestureRecognizer(pinchGestureRecognizer)
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTapGestureRecognizer)
        imageView.isUserInteractionEnabled = true
    }
}
