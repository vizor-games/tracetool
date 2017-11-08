

## tracetools

```
android:
  working_dir: /tmp/traced/android
  provider:
    zip:
      provider:
        http:
          url: https://#{user}:#{pass}@s-debug.shadowlands.ru/zombiemobile-res/:buildname:/:buildname:.symbols.zip

ios:
  working_dir: /tmp/traced/ios
  provider:
    zip:
      provider:
        http:
          url: https://#{user}:#{pass}@s-debug.shadowlands.ru/zombiemobile-res/:buildname:/:buildname:-bundle.zip
```

## tracetoolw

### Example configuration

```
web:
  port: 9292 # default is 8080

unpacker:
  android:
    working_dir: /tmp/traced/android
    provider:
      zip:
        provider:
          http:
            url: https://#{user}:#{pass}@s-debug.shadowlands.ru/zombiemobile-res/:buildname:/:buildname:.symbols.zip

  ios:
    working_dir: /tmp/traced/ios
    provider:
      zip:
        provider:
          http:
            url: https://#{user}:#{pass}@s-debug.shadowlands.ru/zombiemobile-res/:buildname:/:buildname:-bundle.zip
```


# Change log

## 0.1.0

* Added `tracetoolw` - web service for unpacking traces

## 0.1.0

* Added `tracetools` - cli service for unpacking traces. `tracetools` working with persistant data storage with configuration defined in yaml file of propper structure. Same way as `tracetoolw` does.

## 0.2.0

* Removed `tracetoolw`. 
