# Trying out a simple file-based blog

Looking for a new place for making notes about my experience with new technologies, I have decided to try a file-based and git-controlled approach. Although popular pages.github.com with Jekyll were quite attractive, I needed more control and power to be able to incorporate small web-services I create from time to time. Another option was toto engine, which is also very nice, but still I needed more freedom. So I have created this small Sinatra app to render my notes in Markdown format (via Redcarpet and pygments.appspot.com). I will continue to polish the app and update this note when the time permits.

BTW, I plan to update the notes using the embedded editor at GitHub and automatically deploy at fluxflex.com. Let's see how it will work.

Example of code highlighting:

```ruby
def test(@arg)
  puts $args
end
```

