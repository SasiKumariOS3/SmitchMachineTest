//
//  ViewController.swift
//  SmitchTest
//
//  Created by Prem kumar on 29/03/20.
//  Copyright © 2020 Sasikumar. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    ///Variable Decration
    let BM_DOMAIN = "local"
    let BM_TYPE = "_http._tcp"
    let BM_PORT : CInt = 8000
    var BM_NAME  : String = ""
    
    var nsNetService : NetService?
    var nsNetServiceBrow : NetServiceBrowser?
    var arrayNetServices = [NetService]()
    
    ///IBOutlet Decration
    @IBOutlet var txtfld_serviceName: UITextField!
    @IBOutlet var txtfld_serviceType: UITextField!
    @IBOutlet var txtfld_ipAddress: UITextField!
    @IBOutlet var txtfld_port: UITextField!
    @IBOutlet var tblview_list: UITableView!
    
    
    //MARK : Lifecycle of ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.BM_NAME = UIDevice.current.name
        self.txtfld_serviceName.text = "\(BM_NAME)"
        self.txtfld_port.text = "\(BM_PORT)"
        self.txtfld_serviceType.text = "\(BM_TYPE)"
        self.txtfld_ipAddress.text = "\(BM_DOMAIN)"
        self.tblview_list.tableFooterView = UIView()
        self.arrayNetServices.removeAll()

    }
    
    ///Business Logic
    func updateInterface () {
        for service in self.arrayNetServices {
            if service.port == -1 {
                print("service \(service.name) of type \(service.type)" +
                    " not yet resolved")
                service.delegate = self
                service.resolve(withTimeout:10)
            } else {
                print("service \(service.name) of type \(service.type)," +
                    "port \(service.port), addresses \(service.addresses)")
            }
        }
        self.tblview_list.reloadData()

    }
    
    //MARK : IBActions
    @IBAction func scanButton_Action(_ sender: UIButton) {
        /// Net service browser.
        print("listening for services...")
        nsNetServiceBrow = NetServiceBrowser()
        nsNetServiceBrow?.delegate = self
        nsNetServiceBrow?.searchForServices(ofType: BM_TYPE, inDomain: BM_DOMAIN)
    }
    @IBAction func publishButton_Action(_ sender: UIButton) {
        /// Net service .
        if self.txtfld_serviceName.text?.count ?? 0 > 1 && self.txtfld_port.text?.count ?? 0 > 1  && self.txtfld_serviceType.text?.count ?? 0 > 1 && self.txtfld_ipAddress.text?.count ?? 0 > 1 {
            nsNetService = NetService(domain: BM_DOMAIN,
                                      type: BM_TYPE, name:  self.txtfld_serviceName.text ?? "", port: Int32(self.txtfld_port?.text ?? "") ?? 0)
                   nsNetService?.delegate = self
                   //   nsNetService?.publish(options: .listenForConnections)
                   nsNetService?.publish()
                   self.txtfld_serviceName.text = ""
                   self.txtfld_port.text = "\(BM_PORT)"
        }
    }
}


//MARK : NetServiceDelegate
extension ViewController : NetServiceDelegate {
    
    func netServiceWillPublish(sender: NetService!) {
        print("netServiceWillPublish:\(sender)")
    }
    
    func netService(sender: NetService, didNotPublish errorDict: [NSObject : AnyObject]) {
        print("didNotPublish:\(sender)")
    }
    
    func netServiceDidPublish(sender: NetService) {
        print("netServiceDidPublish:\(sender)")
    }
    
    func netServiceWillResolve(sender: NetService) {
        print("netServiceWillResolve:\(sender)")
    }
    
    func netService(sender: NetService, didNotResolve errorDict: [NSObject : AnyObject]) {
        print("netServiceDidNotResolve:\(sender)")
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("netServiceDidResolve:\(sender)")
        self.updateInterface()
        for address in sender.addresses ?? [] {
            do {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                try address.withUnsafeBytes { (pointer:UnsafePointer<sockaddr>) -> Void in
                    guard getnameinfo(pointer, socklen_t(address.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 else {
                        throw NSError(domain: "domain", code: 0, userInfo: ["error":"unable to get ip address"])
                    }
                }
                let ipAddress = String(cString: hostname)
                print("ipAddress = ", ipAddress)
                // heres your IP!
            } catch {
                print(error)
            }
        }
    }
    
    private func netService(sender: NetService, didUpdateTXTRecordData data: NSData) {
        print("netServiceDidUpdateTXTRecordData:\(sender)");
    }
    
    func netServiceDidStop(sender: NetService) {
        print("netServiceDidStopService:\(sender)");
    }
    
    func netService(_ sender: NetService,
                    didAcceptConnectionWith inputStream: InputStream,
                    outputStream stream: OutputStream) {
        print("netServiceDidAcceptConnection:\(sender)");
    }
}
//MARK : NetServiceBrowserDelegate
extension ViewController : NetServiceBrowserDelegate {
    func netServiceBrowser(_ netServiceBrowser: NetServiceBrowser,
                           didFindDomain domainName: String,
                           moreComing moreDomainsComing: Bool) {
        print("netServiceDidFindDomain")
    }
    
    func netServiceBrowser(_ netServiceBrowser: NetServiceBrowser,
                           didRemoveDomain domainName: String,
                           moreComing moreDomainsComing: Bool) {
        print("netServiceDidRemoveDomain")
    }
    
    func netServiceBrowser(_ netServiceBrowser: NetServiceBrowser,
                           didFind netService: NetService,
                           moreComing moreServicesComing: Bool) {
        print("netServiceDidFindService =\( netService.domain) = \(netService.type ) = \(netService.name) = \(netService.port) = \(netService.addresses)")
        print("adding a service")
        self.arrayNetServices.append(netService)
        if !moreServicesComing {
            self.updateInterface()
        }
        
        for address in netService.addresses ?? [] {
            do {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                try address.withUnsafeBytes { (pointer:UnsafePointer<sockaddr>) -> Void in
                    guard getnameinfo(pointer, socklen_t(address.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 else {
                        throw NSError(domain: "domain", code: 0, userInfo: ["error":"unable to get ip address"])
                    }
                }
                let ipAddress = String(cString: hostname)
                print("ipAddress = ", ipAddress)
                // heres your IP!
            } catch {
                print(error)
            }
        }
    }
    
    func netServiceBrowser(_ netServiceBrowser: NetServiceBrowser,
                           didRemove netService: NetService,
                           moreComing moreServicesComing: Bool) {
        print("netServiceDidRemoveService")
//        if let ix = self.arrayNetServices.index(of:netService) {
//            self.arrayNetServices.remove(at:ix)
//            print("removing a service")
//            if !moreServicesComing {
//                self.updateInterface()
//            }
//        }
    }
    
    func netServiceBrowserWillSearch(aNetServiceBrowser: NetServiceBrowser!){
        print("netServiceBrowserWillSearch")
    }
    
    private func netServiceBrowser(netServiceBrowser: NetServiceBrowser,
                                   didNotSearch errorInfo: [NSObject : AnyObject]) {
        print("netServiceDidNotSearch")
    }
    
    func netServiceBrowserDidStopSearch(_ netServiceBrowser: NetServiceBrowser) {
        print("netServiceDidStopSearch")
    }
}
//MARK : UITableViewDataSource && UITableViewDelegate
extension ViewController : UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrayNetServices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath) as! TableCell
        let service = arrayNetServices[indexPath.row]
        cell.lbl_serviceName!.text = "\(service.name)"
        cell.lbl_serviceType!.text = "\(service.type)"
        cell.lbl_port!.text = "\(service.port)"
        for address in service.addresses ?? [] {
            do {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                try address.withUnsafeBytes { (pointer:UnsafePointer<sockaddr>) -> Void in
                    guard getnameinfo(pointer, socklen_t(address.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 else {
                        throw NSError(domain: "domain", code: 0, userInfo: ["error":"unable to get ip address"])
                    }
                }
                // heres your IP!
                if let numAddress = String(validatingUTF8: hostname) {
                    cell.lbl_ipaddress!.text = "\(numAddress)"
                }
            } catch {
                print(error)
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           print("Num: \(indexPath.row)")
       }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return  120
    }
}

class TableCell: UITableViewCell {
    @IBOutlet var lbl_serviceName: UILabel!
    @IBOutlet var lbl_serviceType: UILabel!
    @IBOutlet var lbl_ipaddress: UILabel!
    @IBOutlet var lbl_port: UILabel!

}
