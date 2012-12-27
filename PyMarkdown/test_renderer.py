

def header(content, header_level):
    return "# " + content + "\n"

def double_emphasis(content):
    return "**" + content + "**"

def emphasis(content):
    return "*" + content + "*"

def paragraph(content):
    return content + "\n\n"

def link(content, link, title):
    return "link: " + content

def list(content, list_type):
    return content

def list_item(content, list_type):
    return "* " + content

def block_quote(content):
    return "> " + content

