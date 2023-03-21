//
//  TaskDetailViewController.swift
//  lab-task-squirrel
//
//  Created by Charlie Hieger on 11/15/22.
//

import UIKit
import MapKit
import PhotosUI

// TODO: Import PhotosUI

class TaskDetailViewController: UIViewController {

    @IBOutlet private weak var completedImageView: UIImageView!
    @IBOutlet private weak var completedLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var attachPhotoButton: UIButton!

    // MapView outlet
    @IBOutlet private weak var mapView: MKMapView!

    var task: Task!

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: Register custom annotation view

        // TODO: Set mapView delegate

        // UI Candy
        mapView.layer.cornerRadius = 12

        updateUI()
        updateMapView()
        
        // Register custom annotation view
        mapView.register(TaskAnnotationView.self, forAnnotationViewWithReuseIdentifier: TaskAnnotationView.identifier)
        // Set mapView delegate
        mapView.delegate = self
    }

    /// Configure UI for the given task
    private func updateUI() {
        titleLabel.text = task.title
        descriptionLabel.text = task.description

        let completedImage = UIImage(systemName: task.isComplete ? "circle.inset.filled" : "circle")

        // calling `withRenderingMode(.alwaysTemplate)` on an image allows for coloring the image via it's `tintColor` property.
        completedImageView.image = completedImage?.withRenderingMode(.alwaysTemplate)

        let color: UIColor = task.isComplete ? .systemBlue : .tertiaryLabel
        completedImageView.tintColor = color

        attachPhotoButton.isHidden = task.isComplete
    }

    @IBAction func didTapAttachPhotoButton(_ sender: Any) {
        // TODO: Check and/or request photo library access authorization.
        // if not authorized, request authorization.
        if PHPhotoLibrary.authorizationStatus(for: .readWrite) != .authorized {
            // request library request
            PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: { [weak self] status in
                switch status {
                case .authorized:
                    // The user authorized access to their photo library
                    // show picker (on main thread)
                    DispatchQueue.main.async {
                        self?.presentImagePicker()
                    }
                default:  // If authorization denied, show alert with option to go to settings to update authorization.
                    // show settings alert (on main thread)
                    DispatchQueue.main.async {
                        // Helper method to show settings alert
                        self?.presentGoToSettingsAlert()
                    }
                }
            })
        } else {
            // If authorized, show photo picker
            presentImagePicker()
        }
    }

    private func presentImagePicker() {
        // TODO: Create, configure and present image picker.
        // create a configuration object
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared());
        
        // select filter for only selecting image
        config.filter = .images;
        
        // Request the original file format. Fastest method as it avoids transcoding.
        config.preferredAssetRepresentationMode = .current;
        
        // allow 1 image to be selected as a time
        config.selectionLimit = 1;
        
        // init a picker, with a config being passed in
        let picker = PHPickerViewController(configuration: config);
        
        // Set the picker delegate so we can receive whatever image the user picks.
        picker.delegate = self;
        
        // present the picker
        present(picker, animated: true);
    }

    func updateMapView() {
        // make sure the task has image location
        guard let imageLocation = task.imageLocation else {
            return;
        }
        // Get the coordinate from the image location. This is the latitude / longitude of the location.
        let coordinate = imageLocation.coordinate;
        
        // TODO: Set map viewing region and scale
        // The span represents the maps's "zoom level". A smaller value yields a more "zoomed in" map area, while a larger value is more "zoomed out".
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005));
        mapView.setRegion(region, animated: true);
        
        // TODO: Add annotation to map view
        let annotation = MKPointAnnotation();
        annotation.coordinate = coordinate;
        mapView.addAnnotation(annotation);
    }
}

// TODO: Conform to PHPickerViewControllerDelegate + implement required method(s)

// TODO: Conform to MKMapKitDelegate + implement mapView(_:viewFor:) delegate method.

// Helper methods to present various alerts
extension TaskDetailViewController {

    /// Presents an alert notifying user of photo library access requirement with an option to go to Settings in order to update status.
    func presentGoToSettingsAlert() {
        let alertController = UIAlertController (
            title: "Photo Access Required",
            message: "In order to post a photo to complete a task, we need access to your photo library. You can allow access in Settings",
            preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }

        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    /// Show an alert for the given error
    private func showAlert(for error: Error? = nil) {
        let alertController = UIAlertController(
            title: "Oops...",
            message: "\(error?.localizedDescription ?? "Please try again...")",
            preferredStyle: .alert)

        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)

        present(alertController, animated: true)
    }
}

extension TaskDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // This is where we'll get the picked image in the next step...
        
        // dismiss the picker
        picker.dismiss(animated: true);
        
        // get the selected image (always the first one as we limit it)
        let result = results.first;
        
        // get the image location
        guard let assetId = result?.assetIdentifier,
              let location = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject?.location else {
            return;
        }
        
        // print the location for testing
        print("📍 Image location coordinate: \(location.coordinate)");
        
        // get a provider first, making sure it's not nil
        guard let provider = result?.itemProvider,
              // make sure the provider can load the image
              provider.canLoadObject(ofClass: UIImage.self) else {
            return;
        }
        
        // load the UIImage from the provider
        provider.loadObject(ofClass: UIImage.self, completionHandler: { [weak self] object, error in
            // handle any error
            if let error = error {
                DispatchQueue.main.async { [weak self] in self?.showAlert(for:error) }
            }
            
            // cast the returned object to UIImage
            guard let image = object as? UIImage else {
                return;
            }
            print("We have an image");
            
            // Update UI on main thread
            DispatchQueue.main.async {
                // update the task
                self?.task.set(image, with: location);
                // update UI
                self?.updateUI();
                // update map view
                self?.updateMapView();
            }
            
        })
    }

}

extension TaskDetailViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Dequeue the annotation view for the specified reuse identifier and annotation.
        // Cast the dequeued annotation view to your specific custom annotation view class, `TaskAnnotationView`
        // 💡 This is very similar to how we get and prepare cells for use in table views.
        guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: TaskAnnotationView.identifier, for: annotation) as? TaskAnnotationView else {
            fatalError("Unable to dequeue TaskAnnotationView")
        }

        // Configure the annotation view, passing in the task's image.
        annotationView.configure(with: task.image)
        return annotationView
    }
}
