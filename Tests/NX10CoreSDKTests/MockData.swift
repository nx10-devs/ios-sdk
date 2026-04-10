//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 10/04/2026.
//

import Foundation

public let saaqTwoPromptFollowOn: String = """
{
  "status": "success",
  "data": {
    "triggerID": "69d9360667dd4a07be5f33c5",
    "dismissable": true,
    "displayBehavior": [
      {
        "blockType": "displayForcedImmediate",
        "id": "69d93606e06174000161da10"
      }
    ],
    "prompt": {
      "blockType": "saaqType2",
      "questionText": "How are you feeling?",
      "multipleSelect": false,
      "options": [
        {
          "feeling": {
            "createdAt": "2026-03-18T09:41:45.885Z",
            "updatedAt": "2026-03-19T11:39:34.867Z",
            "suggestedEmoji": "\\U0001F60B",
            "feelingsType": "fun",
            "displayName": "Fun",
            "id": "69ba7359217eedc23866e6d1"
          },
          "followonQuestion": [
            {
              "blockType": "saaqType1",
              "questionText": "How fun?",
              "leftAnchorValue": "Lots",
              "rightAnchorValue": "Meh",
              "rangeSize": 100,
              "startingValue": 0,
              "confirmButtonEnabled": true,
              "id": "69d93606e06174000161da0a"
            }
          ],
          "id": "69d93606e06174000161da0b"
        },
        {
          "feeling": {
            "createdAt": "2026-03-18T09:42:04.850Z",
            "updatedAt": "2026-03-19T11:39:19.154Z",
            "suggestedEmoji": "\\U0001F60E",
            "feelingsType": "relaxed",
            "displayName": "Relaxed",
            "id": "69ba736c217eedc23866e6ef"
          },
          "followonQuestion": [],
          "id": "69d93606e06174000161da0c"
        },
        {
          "feeling": {
            "createdAt": "2026-03-18T09:42:41.741Z",
            "updatedAt": "2026-03-19T11:38:40.485Z",
            "suggestedEmoji": "\\U0002639",
            "feelingsType": "bored",
            "displayName": "Bored",
            "id": "69ba7391217eedc23866e72b"
          },
          "followonQuestion": [],
          "id": "69d93606e06174000161da0d"
        },
        {
          "feeling": {
            "createdAt": "2026-03-18T09:43:17.093Z",
            "updatedAt": "2026-03-19T11:37:58.913Z",
            "suggestedEmoji": "\\U0001F60A",
            "feelingsType": "enjoyment",
            "displayName": "Enjoyment",
            "id": "69ba73b5217eedc23866e767"
          },
          "followonQuestion": [],
          "id": "69d93606e06174000161da0e"
        }
      ],
      "id": "69d93606e06174000161da0f",
      "blockName": "Warrd - Single select SaaQ 2"
    }
  }
}
"""
