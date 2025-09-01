import gleam/list
import gleam/option
import gleeunit
import glisse

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn parse_rss_test() {
  let rss_xml =
    "
    <rss version=\"2.0\">
      <channel>
        <title>Example RSS Feed</title>
        <link>http://www.example.com/</link>
        <description>This is an example RSS feed</description>
        <item>
          <title>First Item</title>
          <link>http://www.example.com/first-item</link>
          <description>This is the first item</description>
          <author>Author #1</author>
        </item>
        <item>
          <title>Second Item</title>
          <link>http://www.example.com/second-item</link>
          <description>This is the second item</description>
          <author>Author #2</author>
        </item>
      </channel>
    </rss>
    "

  let assert Ok(rss_doc) = glisse.parse_rss(rss_xml)

  assert rss_doc.version == "2.0"
  assert rss_doc.channel.title == "Example RSS Feed"
  assert rss_doc.channel.link == "http://www.example.com/"
  assert rss_doc.channel.description == "This is an example RSS feed"
  assert rss_doc.channel.language == option.None
  assert rss_doc.channel.items |> list.length() == 2

  let assert Ok(first_item) = list.first(rss_doc.channel.items)
  assert first_item.title == option.Some("First Item")
  assert first_item.link == option.Some("http://www.example.com/first-item")
  assert first_item.description == option.Some("This is the first item")
  assert first_item.author == option.Some("Author #1")
}
