//
//  MessageFilterExtension.swift
//  smsfilter
//

import IdentityLookup
import os.log
import Combine

final class MessageFilterExtension: ILMessageFilterExtension {

    var filters = [Filter]()
    var filterStore = FilterStoreFile()
    var cancellables = [AnyCancellable]()

    override init() {
        os_log("FILTEREXTENSION - Message filtering Started.", log: OSLog.messageFilterLog, type: .info)
        super.init()
        fetchFilters()
    }

    deinit {
        os_log("FILTEREXTENSION - Message filtering complete.", log: OSLog.messageFilterLog, type: .info)
    }

    func fetchFilters() {
        filterStore.fetch()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: {_ in
            }, receiveValue: { [weak self] result in
                os_log("FILTEREXTENSION - Filter list loaded", log: OSLog.messageFilterLog, type: .info)
                self?.filters = result
            })
            .store(in: &self.cancellables)
    }

}

extension MessageFilterExtension: ILMessageFilterQueryHandling {

    func handle(_ queryRequest: ILMessageFilterQueryRequest,
                context: ILMessageFilterExtensionContext,
                completion: @escaping (ILMessageFilterQueryResponse) -> Void) {

        let response = ILMessageFilterQueryResponse()
        guard let sender = queryRequest.sender, let messageBody = queryRequest.messageBody  else {
            response.action = .none
            completion(response)
            return
        }
        let filter = SMSOfflineFilter(filterList: filters)
        response.action = filter.filterMessage(message: SMSMessage(sender: sender, text: messageBody))
        os_log("FILTEREXTENSION - Filtering done", log: OSLog.messageFilterLog, type: .info)        
        completion(response)
    }
}
