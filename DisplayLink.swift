//
//  DisplayLink.swift
//  Charts
//
//  Created by Jean-Daniel Dupas on 05/12/2018.
//

import Foundation

/** On OS X there is no CADisplayLink. Use a 60 fps timer to render the animations. */
#if os(macOS)
class DisplayLink {
  private var timer: DispatchSourceTimer? = nil
  private var displayLink: CVDisplayLink?
  private var _callback: (TimeInterval) -> ()

  init(callback: @escaping (TimeInterval) -> ()) {
    self._callback = callback
    if CVDisplayLinkCreateWithActiveCGDisplays(&displayLink) == kCVReturnSuccess {
      CVDisplayLinkSetOutputHandler(displayLink!, { (displayLink, inNow, inOutputTime, flagsIn, flagsOut) -> CVReturn in

        // It should probably be better to use .sync, but we can't as it cause deadlock when stop is called
        let targetTime : Double = Double(inOutputTime.pointee.hostTime) / CVGetHostClockFrequency()
        DispatchQueue.main.async {
          self._callback(targetTime)
        }

        return kCVReturnSuccess
      })
    }
    else
    {
      timer = DispatchSource.makeTimerSource(flags: .strict, queue: DispatchQueue.main)
      timer?.setEventHandler {
        self._callback(CACurrentMediaTime())
      }
      timer?.schedule(deadline: DispatchTime.now(), repeating: 1.0 / 60)
    }
  }

  deinit
  {
    stop()
  }

  func start() -> TimeInterval {
    if let displayLink = displayLink {
      CVDisplayLinkStart(displayLink)
    } else if let timer = timer {
      timer.resume()
    }
    return CACurrentMediaTime()
  }

  func stop() {
    if let displayLink = displayLink {
      // Avoid dead lock
      CVDisplayLinkStop(displayLink)
    } else if let timer = timer {
      timer.cancel()
      self.timer = nil
    }
  }
}
#else
class DisplayLink : NSObject {
  private var _displayLink: CADisplayLink!
  private var _callback: (TimeInterval) -> ()

  init(callback: @escaping (TimeInterval) -> ()) {
    self._callback = callback
    super.init()
    _displayLink = CADisplayLink(target: self, selector: #selector(_displayFrame))
  }

  @objc
  private func _displayFrame(_ sender: CADisplayLink) {
    if #available(iOSApplicationExtension 10.0, *) {
      _callback(sender.targetTimestamp)
    } else {
      _callback(sender.timestamp)
    }
  }

  deinit {
    stop()
  }

  func start() -> TimeInterval {
    _displayLink.add(to: .main, forMode: .common)
    return CACurrentMediaTime()
  }

  func stop() {
    _displayLink.remove(from: .main, forMode: .common)
  }
}
#endif

