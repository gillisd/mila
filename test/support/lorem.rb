module Support
  module Lorem
    module_function

    def json_to_embedded_html(json_string)
      # Parse and re-stringify the JSON to ensure proper formatting
      parsed_json = JSON.parse(json_string)
      formatted_json = JSON.pretty_generate(parsed_json)

      # Generate Lorem Ipsum paragraphs for padding
      lorem_paragraphs = [
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam vehicula magna eget mauris lacinia, in finibus tellus volutpat. Suspendisse potenti. Cras eget libero vitae nisl faucibus faucibus.",
        "Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus.",
        "Donec sed odio dui. Donec ullamcorper nulla non metus auctor fringilla. Maecenas sed diam eget risus varius blandit sit amet non magna. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.",
        "Praesent commodo cursus magna, vel scelerisque nisl consectetur et. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam porta sem malesuada magna mollis euismod."
      ]

      # Create the HTML document with embedded JSON
      html = <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Document with Embedded JSON</title>
          <style>
            body {
              font-family: Arial, sans-serif;
              line-height: 1.6;
              max-width: 800px;
              margin: 0 auto;
              padding: 20px;
            }
            .json-container {
              background-color: #f8f8f8;
              border: 1px solid #ddd;
              border-radius: 5px;
              padding: 15px;
              margin: 20px 0;
              overflow-x: auto;
            }
            pre {
              white-space: pre-wrap;
              margin: 0;
            }
            h1, h2 {
              color: #333;
            }
          </style>
        </head>
        <body>
          <h1>Sample Document with Embedded JSON</h1>
          
          <p>#{lorem_paragraphs[0]}</p>
          <p>#{lorem_paragraphs[1]}</p>
          
          <h2>Data Section</h2>
          <p>Below is the JSON data structure that will be processed by our system:</p>
          
          <div class="json-container">
            <pre><code>#{formatted_json}</code></pre>
          </div>
          
          <p>#{lorem_paragraphs[2]}</p>
          <p>#{lorem_paragraphs[3]}</p>
          
          <h2>Additional Information</h2>
          <p>This document was generated on #{Time.now.strftime("%B %d, %Y at %H:%M")}.</p>
          <p>Please refer to the JSON structure above when submitting data to our API.</p>
        </body>
        </html>
      HTML

      html
    end
  end
end