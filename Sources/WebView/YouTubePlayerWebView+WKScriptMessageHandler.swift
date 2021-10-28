import Foundation
import WebKit

// MARK: - YouTubePlayerWebView+WKScriptMessageHandler

extension YouTubePlayerWebView: WKScriptMessageHandler {
    
    /// UserContentController did receive message
    /// - Parameters:
    ///   - userContentController: The WKUserContentController
    ///   - message: The WKScriptMessage
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        // Verify JavaScriptEvent can be initialized from message name
        guard let javaScriptEvent = YouTubePlayer.HTML.JavaScriptEvent(
            rawValue: message.name
        ) else {
            // Otherwise return out of function
            return
        }
        // Switch on JavaScriptEvent
        switch javaScriptEvent {
        case .onIframeAPIReady:
            // Simply do nothing
            break
        case .onIframeAPIFailedToLoad:
            // Send error state
            self.playerStateSubject.send(.error(.iFrameAPIFailedToLoad))
        case .onReady:
            // Send ready state
            self.playerStateSubject.send(.ready)
            // Check if autoPlay is enabled
            if self.player.configuration.autoPlay == true {
                // Play Video
                self.play()
            }
            player.getPlaybackRate { result in
                switch result {
                case .success(let playbackRate): self.playbackRateSubject.send(playbackRate)
                case .failure: break
                }
            }
            player.getPlaybackState { result in
                switch result {
                case .success(let playbackState): self.playbackStateSubject.send(playbackState)
                case .failure: break
                }
            }
        case .onStateChange:
            // Verify PlaybackState is available from message body
            guard let body = message.body as? Int,
                    let playbackState = YouTubePlayer.PlaybackState(rawValue: body) else {
                // Otherwise return out of function
                return
            }
            // Send PlaybackState
            self.playbackStateSubject.send(playbackState)
        case .onPlaybackQualityChange:
            // Verify PlaybackQuality is available from message body
            guard let body = message.body as? String,
                    let playbackQuality = YouTubePlayer.PlaybackQuality(rawValue: body) else {
                // Otherwise return out of function
                return
            }
            // Send PlaybackQuality
            self.playbackQualitySubject.send(playbackQuality)
        case .onPlaybackRateChange:
            // Verify PlaybackRate is available from message body
            guard let playbackRate = message.body as? YouTubePlayer.PlaybackRate else {
                // Otherwise return out of function
                return
            }
            // Send PlaybackRate
            self.playbackRateSubject.send(playbackRate)
        case .onError:
            // Verify Error is available from message body
            guard let body = message.body as? Int,
                    let error = YouTubePlayer.Error(errorCode: body) else {
                // Otherwise return out of function
                return
            }
            // Send PlaybackQuality
            self.playerStateSubject.send(.error(error))
        }
    }
    
}
