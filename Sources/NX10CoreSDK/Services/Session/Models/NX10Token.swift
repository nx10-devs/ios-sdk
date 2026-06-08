//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 08/06/2026.
//

import Foundation
import JWTDecode

public struct NX10Token: Decodable {
    
    public let role: String?
    public let asSessionId: String?
    public let asSourceId: String?
    public let asDeploymentId: String?
    public let asOrganisationId: String?
    public let asVersion: String?
    public let sub: String?
    public let iat: Int?
    public let exp: Int?
    public let aud: String?
    public let iss: String?
    public let expired: Bool?
    
    public init(
        role: String?,
        asSessionId: String?,
        asSourceId: String?,
        asDeploymentId: String?,
        asOrganisationId: String?,
        asVersion: String?,
        sub: String?,
        iat: Int?,
        exp: Int?,
        aud: String?,
        iss: String?,
        expired: Bool?
    ) {
        self.role = role
        self.asSessionId = asSessionId
        self.asSourceId = asSourceId
        self.asDeploymentId = asDeploymentId
        self.asOrganisationId = asOrganisationId
        self.asVersion = asVersion
        self.sub = sub
        self.iat = iat
        self.exp = exp
        self.aud = aud
        self.iss = iss
        self.expired = expired
    }
    
    static func createToken(from token: String?) -> NX10Token? {
        guard let token else {
            return nil
        }
        
        guard
            let decodedToken = try? decode(jwt: token)
        else {
            return nil
        }
        let body = decodedToken.body

        return NX10Token(
            role: body["role"] as? String,
            asSessionId: body["asSessionId"] as? String,
            asSourceId: body["asSourceId"] as? String,
            asDeploymentId: body["asDeploymentId"] as? String,
            asOrganisationId: body["asOrganisationId"] as? String,
            asVersion: body["asVersion"] as? String,
            sub: body["sub"] as? String,
            iat: body["iat"] as? Int,
            exp: body["exp"] as? Int,
            aud: body["aud"] as? String,
            iss: body["iss"] as? String,
            expired: decodedToken.expired
        )
    }
}

/*{
 "role": "user",
 "asSessionId": "Ses-mgjiZSqK7RG2LJZIdeC64",
 "asSourceId": "Src-idGVRuAxCM",
 "asDeploymentId": "Dep-EeDcGN",
 "asOrganisationId": "Org-0sl3YbTN7w",
 "asVersion": "v1",
 "sub": "Ses-mgjiZSqK7RG2LJZIdeC64",
 "iat": 1780927754,
 "exp": 1781532554,
 "aud": "AS",
 "iss": "AS-TOKEN"
}
 */
