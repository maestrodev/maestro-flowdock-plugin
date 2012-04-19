# maestro-flowdock-plugin
Maestro plugin providing a "task" to send flowdock messages. This
plugin is a Ruby-based deployable that gets delivered as a Zip file.

<http://flowdock.com/>

Manifest:

* src/flowdock_worker.rb
* manifest.json
* README.md (this file)

## The Task
This Flowdock plugin requires a few inputs:

* **nickanme** (for the Message From)
* **api_token** (Flowdock API Token)
* **tags** (list of tags used in the message)
* **message** (message to be posted)


## License
Apache 2.0 License: <http://www.apache.org/licenses/LICENSE-2.0.html>

