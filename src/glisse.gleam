import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleaxml
import gleaxml/parser

pub type RssDocument {
  RssDocument(version: String, channel: RssChannel)
}

pub type RssChannel {
  RssChannel(
    title: String,
    link: String,
    description: String,
    language: option.Option(String),
    copyright: option.Option(String),
    managing_editor: option.Option(String),
    web_master: option.Option(String),
    pub_date: option.Option(String),
    last_build_date: option.Option(String),
    category: option.Option(String),
    generator: option.Option(String),
    docs: option.Option(String),
    cloud: option.Option(RssCloud),
    ttl: option.Option(Int),
    image: option.Option(RssImage),
    rating: option.Option(String),
    text_input: option.Option(RssTextInput),
    skip_hours: List(Int),
    skip_days: List(String),
    items: List(RssItem),
  )
}

pub type RssCloud {
  RssCloud(
    domain: String,
    port: Int,
    path: String,
    register_procedure: String,
    protocol: String,
  )
}

pub type RssImage {
  RssImage(
    url: String,
    title: String,
    link: String,
    width: option.Option(Int),
    height: option.Option(Int),
    description: option.Option(String),
  )
}

pub type RssTextInput {
  RssTextInput(title: String, description: String, name: String, link: String)
}

pub type RssItem {
  RssItem(
    title: option.Option(String),
    link: option.Option(String),
    description: option.Option(String),
    author: option.Option(String),
    category: List(RssCategory),
    comments: option.Option(String),
    enclosure: option.Option(RssEnclosure),
    guid: option.Option(RssGuid),
    pub_date: option.Option(String),
    source: option.Option(RssSource),
  )
}

pub type RssSource {
  RssSource(url: String, value: String)
}

pub type RssEnclosure {
  RssEnclosure(url: String, length: Int, type_: String)
}

pub type RssCategory {
  RssCategory(domain: option.Option(String), value: String)
}

pub type RssGuid {
  RssGuid(is_perma_link: option.Option(Bool), value: String)
}

pub fn parse_rss(xml: String) -> Result(RssDocument, String) {
  use xml_doc <- result.try(gleaxml.parse(xml))
  use rss_doc <- result.try(parse_doc(xml_doc))
  Ok(rss_doc)
}

fn parse_doc(doc: parser.XmlDocument) -> Result(RssDocument, String) {
  use chan <- result.try(gleaxml.get_node(doc.root_element, ["rss", "channel"]))
  use version <- result.try(gleaxml.get_attribute(doc.root_element, "version"))
  use channel <- result.try(parse_channel(chan))

  Ok(RssDocument(version:, channel:))
}

fn parse_channel(chan: parser.XmlNode) -> Result(RssChannel, String) {
  use title <- result.try(get_required_text(chan, ["channel", "title"]))
  use link <- result.try(get_required_text(chan, ["channel", "link"]))
  use description <- result.try(
    get_required_text(chan, ["channel", "description"]),
  )

  let language = get_optional_text(chan, ["channel", "language"])
  let copyright = get_optional_text(chan, ["channel", "copyright"])
  let managing_editor = get_optional_text(chan, ["channel", "managingEditor"])
  let web_master = get_optional_text(chan, ["channel", "webMaster"])
  let pub_date = get_optional_text(chan, ["channel", "pubDate"])
  let last_build_date = get_optional_text(chan, ["channel", "lastBuildDate"])
  let category = get_optional_text(chan, ["channel", "category"])
  let generator = get_optional_text(chan, ["channel", "generator"])
  let docs = get_optional_text(chan, ["channel", "docs"])
  let cloud =
    gleaxml.get_node(chan, ["channel", "cloud"])
    |> result.try(parse_cloud)
    |> option.from_result()
  let ttl =
    gleaxml.get_node(chan, ["channel", "ttl"])
    |> result.try(parse_ttl)
    |> option.from_result()
  let image =
    gleaxml.get_node(chan, ["channel", "image"])
    |> result.try(parse_image)
    |> option.from_result()
  let rating = get_optional_text(chan, ["channel", "rating"])
  let text_input =
    gleaxml.get_node(chan, ["channel", "textInput"])
    |> result.try(parse_text_input)
    |> option.from_result()
  let skip_hours =
    gleaxml.get_nodes(chan, ["channel", "skipHours", "hour"])
    |> list.flat_map(gleaxml.get_nonempty_texts)
    |> list.filter_map(int.parse)
  let skip_days =
    gleaxml.get_nodes(chan, ["channel", "skipDays", "day"])
    |> list.flat_map(gleaxml.get_nonempty_texts)
  let items =
    gleaxml.get_nodes(chan, ["channel", "item"])
    |> list.filter_map(parse_item)

  Ok(RssChannel(
    title:,
    link:,
    description:,
    language:,
    copyright:,
    managing_editor:,
    web_master:,
    pub_date:,
    last_build_date:,
    category:,
    generator:,
    docs:,
    cloud:,
    ttl:,
    image:,
    rating:,
    text_input:,
    skip_hours:,
    skip_days:,
    items:,
  ))
}

fn parse_cloud(node: parser.XmlNode) -> Result(RssCloud, String) {
  use domain <- result.try(gleaxml.get_attribute(node, "domain"))
  use port_str <- result.try(gleaxml.get_attribute(node, "port"))
  use path <- result.try(gleaxml.get_attribute(node, "path"))
  use register_procedure <- result.try(gleaxml.get_attribute(
    node,
    "registerProcedure",
  ))
  use protocol <- result.try(gleaxml.get_attribute(node, "protocol"))

  use port <- result.try(
    int.parse(port_str)
    |> result.replace_error("Invalid port number"),
  )

  Ok(RssCloud(domain:, port:, path:, register_procedure:, protocol:))
}

fn parse_ttl(node: parser.XmlNode) -> Result(Int, String) {
  gleaxml.get_nonempty_texts(node)
  |> string.join("")
  |> int.parse()
  |> result.replace_error("Invalid TTL value")
}

fn parse_image(node: parser.XmlNode) -> Result(RssImage, String) {
  use url <- result.try(get_required_text(node, ["image", "url"]))
  use title <- result.try(get_required_text(node, ["image", "title"]))
  use link <- result.try(get_required_text(node, ["image", "link"]))

  let width =
    get_required_text(node, ["image", "width"])
    |> result.replace_error(Nil)
    |> result.try(int.parse)
    |> option.from_result()
  let height =
    get_required_text(node, ["image", "height"])
    |> result.replace_error(Nil)
    |> result.try(int.parse)
    |> option.from_result()
  let description = get_optional_text(node, ["image", "description"])

  Ok(RssImage(url:, title:, link:, width:, height:, description:))
}

fn parse_text_input(node: parser.XmlNode) -> Result(RssTextInput, String) {
  use title <- result.try(get_required_text(node, ["textInput", "title"]))
  use description <- result.try(
    get_required_text(node, ["textInput", "description"]),
  )
  use name <- result.try(get_required_text(node, ["textInput", "name"]))
  use link <- result.try(get_required_text(node, ["textInput", "link"]))

  Ok(RssTextInput(title:, description:, name:, link:))
}

fn parse_item(item: parser.XmlNode) -> Result(RssItem, String) {
  let title = get_optional_text(item, ["item", "title"])
  let link = get_optional_text(item, ["item", "link"])
  let description = get_optional_text(item, ["item", "description"])
  let author = get_optional_text(item, ["item", "author"])
  let category =
    gleaxml.get_nodes(item, ["item", "category"])
    |> list.filter_map(parse_category)
  let comments = get_optional_text(item, ["item", "comments"])
  let enclosure =
    gleaxml.get_node(item, ["item", "enclosure"])
    |> result.try(parse_enclosure)
    |> option.from_result()
  let guid =
    gleaxml.get_node(item, ["item", "guid"])
    |> result.try(parse_guid)
    |> option.from_result()
  let pub_date = get_optional_text(item, ["item", "pubDate"])
  let source =
    gleaxml.get_node(item, ["item", "source"])
    |> result.try(parse_source)
    |> option.from_result()

  case title, description {
    option.None, option.None ->
      Error("Item must have at least a title or description")
    _, _ ->
      Ok(RssItem(
        title:,
        link:,
        description:,
        author:,
        category:,
        comments:,
        enclosure:,
        guid:,
        pub_date:,
        source:,
      ))
  }
}

fn parse_source(node: parser.XmlNode) -> Result(RssSource, String) {
  use url <- result.try(gleaxml.get_attribute(node, "url"))
  use value <- result.try(get_required_text(node, ["source"]))

  Ok(RssSource(url:, value:))
}

fn parse_enclosure(node: parser.XmlNode) -> Result(RssEnclosure, String) {
  use url <- result.try(gleaxml.get_attribute(node, "url"))
  use length_str <- result.try(gleaxml.get_attribute(node, "length"))
  use type_ <- result.try(gleaxml.get_attribute(node, "type"))

  use length <- result.try(
    int.parse(length_str)
    |> result.replace_error("Invalid length value"),
  )

  Ok(RssEnclosure(url:, length:, type_:))
}

fn parse_category(node: parser.XmlNode) -> Result(RssCategory, String) {
  let domain =
    gleaxml.get_attribute(node, "domain")
    |> option.from_result()
  use value <- result.try(get_required_text(node, ["category"]))

  Ok(RssCategory(domain:, value:))
}

fn parse_guid(node: parser.XmlNode) -> Result(RssGuid, String) {
  let is_perma_link =
    gleaxml.get_attribute(node, "isPermaLink")
    |> result.map(fn(v) { v == "true" })
    |> option.from_result()
  use value <- result.try(get_required_text(node, ["guid"]))

  Ok(RssGuid(is_perma_link:, value:))
}

fn get_required_text(
  node: parser.XmlNode,
  path: List(String),
) -> Result(String, String) {
  gleaxml.get_node(node, path)
  |> result.map(gleaxml.get_nonempty_texts)
  |> result.map(string.join(_, " "))
}

fn get_optional_text(
  node: parser.XmlNode,
  path: List(String),
) -> option.Option(String) {
  gleaxml.get_node(node, path)
  |> option.from_result()
  |> option.map(gleaxml.get_nonempty_texts)
  |> option.map(string.join(_, " "))
}
