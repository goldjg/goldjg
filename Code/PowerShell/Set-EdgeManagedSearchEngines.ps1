New-Item HKLM:\SOFTWARE\Policies\Microsoft\Edge\ManagedSearchEngines
New-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Edge\ManagedSearchEngines =
[
    {
      "allow_search_engine_discovery": true
    },
    {
      "is_default": true,
      "keyword": "example1.com",
      "name": "Example1",
      "search_url": "https://www.example1.com/search?q={searchTerms}",
      "suggest_url": "https://www.example1.com/qbox?query={searchTerms}"
    },
    {
      "image_search_post_params": "content={imageThumbnail},url={imageURL},sbisrc={SearchSource}",
      "image_search_url": "https://www.example2.com/images/detail/search?iss=sbiupload",
      "keyword": "example2.com",
      "name": "Example2",
      "search_url": "https://www.example2.com/search?q={searchTerms}",
      "suggest_url": "https://www.example2.com/qbox?query={searchTerms}"
    },
    {
      "encoding": "UTF-8",
      "image_search_url": "https://www.example3.com/images/detail/search?iss=sbiupload",
      "keyword": "example3.com",
      "name": "Example3",
      "search_url": "https://www.example3.com/search?q={searchTerms}",
      "suggest_url": "https://www.example3.com/qbox?query={searchTerms}"
    },
    {
      "keyword": "example4.com",
      "name": "Example4",
      "search_url": "https://www.example4.com/search?q={searchTerms}"
    }
  ]