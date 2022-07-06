# minemeld-wd-atp

MineMeld nodes for Microsoft Defender for Endpoint API aka. Windows Defender ATP.

This uses the API calls described here: https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/ti-indicator?view=o365-worldwide

# Notes

## Defender for Endpoint API Indicator Limits

The limit is 15,000 indicators. The errors will be obvious if you're hitting the limit,

```
2022-07-05T00:58:29 (147)node._push_indicators ERROR: defender_demo: error submitting indicator 203.0.113.0: Max capacity exceeded. Current Total: 15000, Limit: 15000 (Parameter 'Capacity: 15000/15000')
```

## Defender for Endpoint API Call Limits

In version 1.1 additional gevent.sleep() calls were added when a 429 response code is received.

These are necessary to ensure the MineMeld extension will back off from trying to interact with the API if the API call limit has been hit.

If this is not actually enough the errors should be obvious, e.g.

```
2022-07-05T00:48:39 (147)node._push_loop ERROR: defender_demo - error submitting indicators - 429 Client Error:  for url: https://api.securitycenter.windows.com/api/indicators/import
2022-07-05T00:48:39 (147)node._push_loop ERROR: defender_demo: error in request - {"error":{"code":"429","message":"API calls quota exceeded! Maximum allowed 30 per 00:01:00 for the key Destination+TenantID+AppID. You can send requests again in 8 seconds.","target":"TENANT_ID"}}
```

## Indicator Removal

The extension, at this point, never actually uses the DELETE method to remove an indicator.

For all requests it uses the "Import Indicator" endpoint method, and **updates** indicators with an expiry time sixty seconds in the future, which triggers the Microsoft Defender for Endpoint API backend to remove the indicator automatically at that time.

This is mostly, I assume, simply to avoid having the MineMeld extension code perform a GET to find the API indicator ID which would be needed in order to perform a DELETE.

It's simpler and more efficient, and minimises API calls to avoid hitting API call limits, but does mean the indicator will remain in the API for another sixty seconds.

This did not work at all in version 0.5 of this extension, as it tried to set the expiry time to epoch time, which is in the past, which leads to this kind of error from the API:

```
2022-07-06T03:18:31 (2430)node._push_loop INFO: defender_demo - Sending 1 indicators
2022-07-06T03:18:32 (2430)node._push_loop ERROR: defender_demo - error submitting indicators - 400 Client Error: Bad Request for url: https://api.securitycenter.windows.com/api/indicators/import
2022-07-06T03:18:32 (2430)node._push_loop ERROR: defender_demo: error in request - {"error":{"code":"BadRequest","message":"Indicator 203.0.113.1 is inactive. (Expiration time should be set to a future date time)","target":"TENANT_ID"}}
```

In version 1.0 by "dont-poke-the-bear"s fork they used 300 seconds instead.

In version 1.2 in this repo we've used 60 seconds instead to still allow for delays in MineMeld queue processing but ensure the indicator is removed quickly.

## Output Node Disconnection From Inputs

**WARNING**

If you disconnect the output node from the inputs, before the inputs have withdrawn all indicators, and hence caused the output node to update the expiry time to sixty seconds from now in the Defender for Endpoint API... then the indicators may not be removed the Defender for Endpoint API indicator list until they expire naturally, or your reconnect the inputs and a withdraw occurs in the future.

For this reason, the extension always sets a default expiry of the last update + 365 days.

The risk is that if you have very static indicators, e.g. in a localDB miner node, that never get updated, they will be removed from the Defender for Endpoint API indicator list after 1 year.

This should be fine as indicators which are that old are probably of very low quality.

You may want to use some kind of review task, or software automation, to ensure localDB miner node indicators are reviewed and updated annually; in order to ensure anything that should continue to be in the Defender for Endpoint API indicator list will do so.

This was the behaviour of a default expiry of last update + 365 days was in version 0.5, but it was removed in version 1.0 by "dont-poke-the-bear" 's fork.

It was reinstated in version 1.2 in this repo.
