//
//  OpenCamera.swift
//  original
//
//  Created by Tiger Udagawa on 2024/11/12.
//

import UIKit

class OpenCamera: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    
    @IBAction func openCameraButtonTapped(_ sender: UIButton)
    {
        if UIImagePickerController.isSourceTypeAvailable(.camera)
        {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        }
        else
        {
            let alert = UIAlertController(title: "Camera not available", message: "Camera not available on this device", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
