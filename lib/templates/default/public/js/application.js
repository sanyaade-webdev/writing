//= require jquery
//= require underscore
//= require backbone
//= require markdown-converter
//= require moment
//= require codemirror
//= require codemirror/runmode
//= require codemirror/modes/javascript
//= require_tree ./templates

var Writing = {
  Collections : {},
  Models      : {},
  Routers     : {},
  Views       : {},

  initialize: function() {
    this.createCollections()
        .loadPosts()
        .createRouters()
        .start();
  },

  createCollections: function() {
    this.posts = new Writing.Collections.Posts();

    return this;
  },

  createRouters: function() {
    new Writing.Routers.Posts();

    return this;
  },

  loadPosts: function() {
    $('script[type="text/post"]').each(function() {
      var url  = $(this).attr("src"),
          text = $(this).text();

      Writing.Models.Post.add(url, text, function(post) {
        Writing.posts.add(post);
      });
    });

    return this;
  },

  start: function() {
    Backbone.history.start();
    Backbone.history.bind("route", function() {
      $(window).scrollTop(0);
    });

    return this;
  }
};

$(function() {
  Writing.initialize();
});




Writing.Routers.Posts = Backbone.Router.extend({
  routes: {
    ""          : "index",
    "posts/:id" : "show"
  },

  index: function() {
    new Writing.Views.Posts.Index({
      collection: Writing.posts
    }).render();
  },

  show: function(id) {
    var post = Writing.posts.get(id);

    if (post) {
      new Writing.Views.Posts.Show({ model: post }).render();
    } else {
      Writing.Models.Post.load("posts/" + id + ".markdown", _.bind(function(post) {
        Writing.posts.add(post);

        Backbone.history.loadUrl(window.location.hash);
      }, this));
    }
  }
});




Writing.Models.Author = Backbone.Model.extend({});

Writing.Models.Post = Backbone.Model.extend({}, {
  add: function(url, text, callback) {
    var blocks  = text.split("\n\n"),
        json    = blocks.shift().replace(/(```javascript\n((.|\n)+)```)/, "$2"),
        options = {};

    try {
      options = JSON.parse(json);
    } catch(exception) {
      if (console) {
        console.warn("Invalid JSON header in", url, "(" + exception.message + ")");
      }

      return;
    }

    callback(new Writing.Models.Post({
      "id"        : url.match(/\/(.+)\.markdown$/)[1],
      "title"     : options.title,
      "author"    : new Writing.Models.Author(options.author),
      "excerpt"   : options.excerpt,
      "content"   : blocks.join("\n\n"),
      "published" : options.published
    }));
  },

  load: function(url, callback) {
    $.get(url, _.bind(function(response) {
      this.add(url, response, callback);
    }, this));
  }
});




Writing.Collections.Posts = Backbone.Collection.extend({
  model: Writing.Models.Post,

  comparator: function(post) {
    return -new Date(post.get("published")).getTime();
  }
});




Writing.Helpers = {
  byline: function(author) {
    var name = author.get("name") || "Unknown",
        href = author.get("link");

    if (href) {
      return $("<div>").append($("<a>", { href: href, text: name })).html();
    } else {
      return name;
    }
  },

  formatDate: function(date, format) {
    return moment(date).format(format || "dddd, MMMM Do YYYY \\at h:mm A")
  },

  markdown: function(text) {
    return Markdown.HighlightingConverter.makeHtml(text);
  }
};




Writing.Views.Posts = {
  Index: Backbone.View.extend({
    template : JST["js/templates/index"],

    initialize: function() {
      this.collection.bind("add", _.bind(this.render, this));
    },

    render: function() {
      $("section").html(this.template({ posts: this.collection, helper: Writing.Helpers }));
    }
  }),

  Show: Backbone.View.extend({
    template : JST["js/templates/show"],

    render: function() {
      $("section").html(this.template({ post: this.model, helper: Writing.Helpers }));
    }
  })
};




Markdown.HighlightingConverter = (function() {
  var converter = new Markdown.Converter(),
      hooks     = converter.hooks;

  hooks.chain("preConversion", function(text) {
    return text.split(/\n\n/).map(function(block) {
      var parts = block.match(/^```(.+)\n((.|\n)+)```$/);

      if (parts) {
        return $("<div>")
                 .append($("<pre>", {
                   "text"          : parts[2],
                   "class"         : "cm-s-lesser-dark highlight",
                   "data-language" : parts[1]
                 })).html();
      } else {
        return block;
      }
    }).join("\n\n");
  });

  hooks.chain("postConversion", function(html) {
    return $("<div>")
             .html(html)
             .find("pre.highlight[data-language]")
               .each(function() {
                 var element = $(this);

                 CodeMirror.runMode(element.text(), { name: element.data("language") }, element.get(0));
               })
             .end()
             .html();
  });

  return converter;
})();
