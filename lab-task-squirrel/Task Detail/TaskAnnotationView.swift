//
//  TaskAnnotationView.swift
//  lab-task-squirrel
//
//  Created by Charlie Hieger on 11/19/22.
//

import UIKit
import MapKit

class TaskAnnotationView: MKAnnotationView {

    // Reuse identifier used for dequeueing the view in map view delegate method.
    // 💡 Similar to table view reuse identifier
    static var identifier = "TaskAnnotationView"

    // Some constants to use when sizing the various views
    enum Constants {
        static let containerViewHeight: CGFloat = 80
        static let containerViewCornerRadius: CGFloat = 16
        static let imageViewPadding: CGFloat = 4
        static var pointerViewHieght: CGFloat { containerViewHeight / 3 }

        // The distance the pointer view extends downwards after rotation. Half of the hypotenuse of the view.
        static var pointerViewHeightAfterRotation: CGFloat { pointerViewHieght * sqrt(2) / 2 }
    }

    // The image view to show the image in the annotation.
    var imageView = UIImageView()

    // Init for MKAnnotationView
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    // Required init. After adding the above init, Xcode will give error/suggestion to add this method.
    // It's required, but we won't use it for our purposes.
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Use this method to pass in and set the image for the annotation.
    func configure(with image: UIImage?) {
        imageView.image = image ?? UIImage(systemName: "pin.fill")
    }

    // Internal funtion to do initial view setup
    private func setupViews() {

        // Container View: The main view for our annotation view
        let containerView = UIView()

        // Set this property to false for any programmatic view that uses programmatic autolayout constraints.
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // `.systemBackground` is a dynamic color (adapts to light/dark modes). Appears "white" in light mode, "black" in dark mode.
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = Constants.containerViewCornerRadius

        // Add the container view to the view hierarchy.
        addSubview(containerView)

        // Set the programmatic auto-layout constraints (in this case height / width)
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: Constants.containerViewHeight),
            containerView.widthAnchor.constraint(equalToConstant: Constants.containerViewHeight)
        ])

        // Pointer View: View that forms the "pointer" tip at the bottom of the annotation view which points to the location.
        let pointerView = UIView()
        pointerView.translatesAutoresizingMaskIntoConstraints = false
        pointerView.backgroundColor = .systemBackground
        pointerView.layer.cornerRadius = 4

        containerView.addSubview(pointerView)
        NSLayoutConstraint.activate([
            pointerView.heightAnchor.constraint(equalToConstant: Constants.pointerViewHieght),
            pointerView.widthAnchor.constraint(equalToConstant: Constants.pointerViewHieght),
            // (X-axis) Pointer view should be centered in the container view.
            pointerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            // (Y-axis) The center of the pointer view should be placed on the bottom edge of the container view.
            pointerView.centerYAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4)
        ])

        // Pointer view is a rectangular view. In order to get a "downward facing triangle" look
        // we'll rotate the pointer view 45 degrees on it's center axis using the `transform` property (available on any UIview / subclass)
        // Transform rotaion uses radians so we'll convert 45 degrees to radians. `radians = degrees * pi / 180`
        let fortyFiveDegreesInRadians = 45 * CGFloat.pi / 180
        pointerView.transform = CGAffineTransform(rotationAngle: fortyFiveDegreesInRadians)

        // Image View
        imageView.translatesAutoresizingMaskIntoConstraints = false

        // The image should fill the entire view while maintaining it's original aspect (i.e. no stretch/distorion).
        // However, any image who's aspect ratio is different than that of our image view (currently a square) will be cropped to some degree.
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = Constants.containerViewCornerRadius - Constants.imageViewPadding

        // Make sure the image doesn't extend beyond the image view bounds.
        imageView.clipsToBounds = true

        containerView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.imageViewPadding),
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Constants.imageViewPadding),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.imageViewPadding),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Constants.imageViewPadding),
        ])

        // Offset the annotation view so the bottom pointer view points to the correct location.
        // The annotation view is originally positioned with it's origin (i.e. top left most corner) placed at the given map coordinate.
        // To compensate, we center the annotation view in the x-axis by moving it to the left by half of it's width.
        // In the y-axis, we move the annotation view up (-y) by it's entire height, + the height that the pointer view extends.
        centerOffset = CGPoint(x: -(Constants.containerViewHeight / 2),
                               y: -Constants.containerViewHeight - Constants.pointerViewHeightAfterRotation)

        // UI Candy: Add a subtle shadow to help the annotation stand out visually against the map view.
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.6
        layer.shadowOffset = CGSize(width: 3, height: 3)
        layer.shadowRadius = 5
    }
}
