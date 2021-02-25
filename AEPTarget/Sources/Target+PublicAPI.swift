/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPCore
import AEPServices
import Foundation

@objc public extension Target {
    /// Prefetch multiple Target mboxes simultaneously.
    ///
    /// Executes a prefetch request to your configured Target server with the TargetPrefetchObject list provided
    /// in the prefetchObjectArray parameter. This prefetch request will use the provided parameters for all of
    /// the prefetches made in this request. The callback will be executed when the prefetch has been completed, returning
    /// an error object, nil if the prefetch was successful or error description if the prefetch was unsuccessful.
    /// The prefetched mboxes are cached in memory for the current application session and returned when requested.
    /// - Parameters:
    ///   - prefetchObjectArray: an array of AEPTargetPrefetch objects representing the desired mboxes to prefetch
    ///   - targetParameters: a TargetParameters object containing parameters for all the mboxes in the request array
    ///   - completion: the callback `closure` which will be called after the prefetch is complete.  The parameter in the callback will be nil if the prefetch completed successfully, or will contain error message otherwise
    @objc(prefetchContent:withParameters:callback:)
    static func prefetchContent(prefetchObjectArray: [TargetPrefetch], targetParameters: TargetParameters?, completion: ((Error?) -> Void)?) {
        let completion = completion ?? { _ in }

        guard !prefetchObjectArray.isEmpty else {
            Log.error(label: Target.LOG_TAG, "Failed to prefetch Target request (the provided request list for mboxes is empty or nil)")
            completion(TargetError(message: TargetError.ERROR_EMPTY_PREFETCH_LIST))
            return
        }
        var prefetchArray = [[String: Any]]()
        for prefetch in prefetchObjectArray {
            if let dict = prefetch.asDictionary() {
                prefetchArray.append(dict)

            } else {
                Log.error(label: Target.LOG_TAG, "Failed to prefetch Target request (the provided prefetch object can't be converted to [String: Any] dictionary), prefetch => \(prefetch)")
                completion(TargetError(message: TargetError.ERROR_INVALID_REQUEST))
                return
            }
        }

        var eventData: [String: Any] = [TargetConstants.EventDataKeys.PREFETCH_REQUESTS: prefetchArray]
        if let targetParametersDict = targetParameters?.asDictionary() {
            eventData[TargetConstants.EventDataKeys.TARGET_PARAMETERS] = targetParametersDict
        }

        let event = Event(name: TargetConstants.EventName.PREFETCH_REQUESTS, type: EventType.target, source: EventSource.requestContent, data: eventData)

        MobileCore.dispatch(event: event) { responseEvent in
            guard let responseEvent = responseEvent else {
                completion(TargetError(message: TargetError.ERROR_TIMEOUT))
                return
            }
            if let errorMessage = responseEvent.data?[TargetConstants.EventDataKeys.PREFETCH_ERROR] as? String {
                completion(TargetError(message: errorMessage))
                return
            }
            completion(.none)
        }
    }

    /// Retrieves content for multiple Target mbox locations at once.
    /// Executes a batch request to your configured Target server for multiple mbox locations. Any prefetched content
    /// which matches a given mbox location is returned and not included in the batch request to the Target server.
    /// Each object in the array contains a callback function, which will be invoked when content is available for
    /// its given mbox location.
    /// - Parameters:
    ///   - requests:  An array of AEPTargetRequestObject objects to retrieve content
    ///   - targetParameters: a TargetParameters object containing parameters for all locations in the requests array
    static func retrieveLocationContent(requests: [TargetRequest], targetParameters: TargetParameters) {
        // TODO: need to verify input parameters
        // TODO: need to convert "requests" to [String:Any] array
        let eventData = [TargetConstants.EventDataKeys.LOAD_REQUESTS: requests, TargetConstants.EventDataKeys.LOAD_REQUESTS: targetParameters] as [String: Any]
        let event = Event(name: TargetConstants.EventName.LOAD_REQUEST, type: EventType.target, source: EventSource.requestContent, data: eventData)
        MobileCore.dispatch(event: event)
    }

    /// Sets the custom visitor ID for Target.
    /// Sets a custom ID to identify visitors (profiles). This ID is preserved between app upgrades,
    /// is saved and restored during the standard application backup process, and is removed at uninstall or
    /// when AEPTarget::resetExperience is called.
    /// - Parameter thirdPartyId: a string pointer containing the value of the third party id (custom visitor id)
    static func setThirdPartyId(_ id: String) {
        // TODO: need to verify input parameters
        let eventData = [TargetConstants.EventDataKeys.THIRD_PARTY_ID: id]
        let event = Event(name: TargetConstants.EventName.REQUEST_IDENTITY, type: EventType.target, source: EventSource.requestIdentity, data: eventData)
        MobileCore.dispatch(event: event)
    }

    /// Gets the custom visitor ID for Target
    /// - Parameter completion:  the callback `closure` will be invoked to return the thirdPartyId value or `nil` if no third-party ID is set
    static func getThirdPartyId(completion _: (String) -> Void) {
        let event = Event(name: TargetConstants.EventName.REQUEST_IDENTITY, type: EventType.target, source: EventSource.requestIdentity, data: nil)
        MobileCore.dispatch(event: event) { _ in
            // TODO:
        }
    }

    /// Gets the Test and Target user identifier.
    /// Retrieves the TnT ID returned by the Target server for this visitor. The TnT ID is set to the
    /// Mobile SDK after a successful call to prefetch content or load requests.
    ///
    /// This ID is preserved between app upgrades, is saved and restored during the standard application
    /// backup process, and is removed at uninstall or when AEPTarget::resetExperience is called.
    ///
    /// - Parameter completion:  the callback `closure` invoked with the current tnt id or `nil` if no tnt id is set.
    static func getTntId(completion _: (String) -> Void) {
        let event = Event(name: TargetConstants.EventName.REQUEST_IDENTITY, type: EventType.target, source: EventSource.requestIdentity, data: nil)
        MobileCore.dispatch(event: event) { _ in
            // TODO:
        }
    }

    /// Sets the Target preview restart deep link.
    /// Set the Target preview URL to be displayed when the preview mode is restarted.
    static func resetExperience() {
        let eventData = [TargetConstants.EventDataKeys.RESET_EXPERIENCE: true]
        let event = Event(name: TargetConstants.EventName.REQUEST_RESET, type: EventType.target, source: EventSource.requestReset, data: eventData)
        MobileCore.dispatch(event: event)
    }

    /// Clears prefetched mboxes.
    /// Clears the cached prefetched AEPTargetPrefetchObject array.
    static func clearPrefetchCache() {
        let eventData = [TargetConstants.EventDataKeys.CLEAR_PREFETCH_CACHE: true]
        let event = Event(name: TargetConstants.EventName.CLEAR_PREFETCH_CACHE, type: EventType.target, source: EventSource.requestReset, data: eventData)
        MobileCore.dispatch(event: event)
    }

    /// Sets the Target preview restart deep link.
    /// Set the Target preview URL to be displayed when the preview mode is restarted.
    /// - Parameter deeplink:  the URL which will be set for preview restart
    static func setPreviewRestartDeepLink(_ deeplink: URL) {
        // TODO: need to verify input parameters
        let eventData = [TargetConstants.EventDataKeys.PREVIEW_RESTART_DEEP_LINK: deeplink.absoluteString]
        let event = Event(name: TargetConstants.EventName.SET_PREVIEW_DEEPLINK, type: EventType.target, source: EventSource.requestContent, data: eventData)
        MobileCore.dispatch(event: event)
    }

    /// Sends a display notification to Target for given prefetched mboxes. This helps Target record location display events.
    /// - Parameters:
    ///   - mboxNames:  (required) an array of displayed location names
    ///   - targetParameters: for the displayed location
    @objc(displayedLocations:withParameters:)
    static func displayedLocations(mboxNames: [String], targetParameters: TargetParameters?) {
        if mboxNames.isEmpty {
            Log.error(label: LOG_TAG, "Failed to send display notification, List of Mbox names must not be empty.")
            return
        }

        let eventData = [TargetConstants.EventDataKeys.MBOX_NAMES: mboxNames, TargetConstants.EventDataKeys.IS_LOCATION_DISPLAYED: true, TargetConstants.EventDataKeys.TARGET_PARAMETERS: targetParameters ?? TargetParameters()] as [String: Any]

        let event = Event(name: TargetConstants.EventName.LOCATIONS_DISPLAYED, type: EventType.target, source: EventSource.requestContent, data: eventData)
        MobileCore.dispatch(event: event)
    }

    /// Sends a click notification to Target if a click metric is defined for the provided location name.
    /// Click notification can be sent for a location provided a load request has been executed for that prefetched or regular mbox
    /// location before, indicating that the mbox was viewed. This request helps Target record the clicked event for the given location or mbox.
    ///
    /// - Parameters:
    ///   - mboxName:  NSString value representing the name for location/mbox
    ///   - targetParameters:  a TargetParameters object containing parameters for the location clicked
    @objc(clickedLocation:withParameters:)
    static func clickedLocation(mboxName: String, targetParameters: TargetParameters?) {
        if mboxName.isEmpty {
            Log.error(label: LOG_TAG, "Failed to send click notification, Mbox name must not be empty or nil.")
            return
        }

        var eventData = [TargetConstants.EventDataKeys.MBOX_NAME: mboxName, TargetConstants.EventDataKeys.IS_LOCATION_CLICKED: true] as [String: Any]

        if let targetParams = targetParameters {
            eventData[TargetConstants.EventDataKeys.TARGET_PARAMETERS] = targetParams
        }

        let event = Event(name: TargetConstants.EventName.LOCATION_CLICKED, type: EventType.target, source: EventSource.requestContent, data: eventData)
        MobileCore.dispatch(event: event)
    }
}