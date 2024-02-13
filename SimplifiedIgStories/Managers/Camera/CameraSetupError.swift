//
//  CameraSetupError.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/06/2022.
//

enum CameraSetupError: Error {
    case defaultVideoDeviceUnavailable
    case createVideoDeviceInputFailure(err: Error)
    case addVideoDeviceInputFailure
    case defaultAudioDeviceUnavailable
    case createAudioDeviceInputFailure(err: Error)
    case addAudioDeviceInputFailure
    case addMovieFileOutputFailure
    case addPhotoOutputFailure
    case backgroundAudioPreferenceSetupFailure
    
    var errMsg: String {
        switch self {
        case .defaultVideoDeviceUnavailable:
            return "Default video device is unavailable."
        case .createVideoDeviceInputFailure(let err):
            return "Cannot create video device input: \(err)"
        case .addVideoDeviceInputFailure:
            return "Cannot add video device input to the session."
        case .defaultAudioDeviceUnavailable:
            return "Default audio device is unavailable."
        case .createAudioDeviceInputFailure(let err):
            return "Cannot create audio device input: \(err)"
        case .addAudioDeviceInputFailure:
            return "Cannot add audio device input to the session."
        case .addMovieFileOutputFailure:
            return "Cannot add movie file output to the session."
        case .addPhotoOutputFailure:
            return "Cannot add photo output to the session."
        case .backgroundAudioPreferenceSetupFailure:
            return "Cannot set background audio preference."
        }
    }
}
