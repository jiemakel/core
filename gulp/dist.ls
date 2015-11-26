require!{
  gulp
  \main-bower-files
  \uglify-save-license
}
$ = require(\gulp-load-plugins)!

gulp.task \dist:partials, ->
  gulp.src(".tmp/partials/**/*.html")
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.ngHtml2js(
      moduleName: "app"
      prefix: "partials/"
    ))
    .pipe(gulp.dest(".tmp/partials"))

gulp.task \dist:html, <[dist:partials]>, ->
  jsFilter = $.filter("**/*.js", {restore:true})
  cssFilter = $.filter("**/*.css", {restore:true})
  gulp.src(".tmp/*.html")
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.print((path)->"dist:html(1) "+path))
    .pipe($.size(title:'dist:html(1)'))
    .pipe($.inject(gulp.src(".tmp/partials/**/*.js"),
      read: false
      starttag: "<!-- inject:partials-->"
      endtag: "<!-- endinject-->"
      addRootSlash: false
      addPrefix: ".."
    ))
    .pipe($.useref!)
    .pipe(jsFilter)
    .pipe($.rev!)
    .pipe($.print((path)->"dist:html-js(1) "+path))
    .pipe($.size(title:'dist:html-js(1)'))
    .pipe($.ngAnnotate!)
    .pipe($.uglify(preserveComments: uglifySaveLicense))
    .pipe($.print((path)->"dist:html-js(2) "+path))
    .pipe($.size(title:'dist:html-js(2)'))
    .pipe(jsFilter.restore)
    .pipe(cssFilter)
    .pipe($.rev!)
    .pipe($.print((path)->"dist:html-css(1) "+path))
    .pipe($.size(title:'dist:html-css(1)'))
    .pipe($.replace(/url\(".*?\/(\w+\.(eot|svg|ttf|woff|woff2).*?)"\)/g,'url("$1")'))
    .pipe($.replace(/url\(".*?\/(\w+?\.(png|jpg|jpeg))"\)/g,'url("$1")'))
    .pipe($.minifyCss(processImport:false))
    .pipe($.print((path)->"dist:html-css(2) "+path))
    .pipe($.size(title:'dist:html-css(2)'))
    .pipe(cssFilter.restore)
    .pipe($.revReplace!)
    .pipe(gulp.dest("dist"))
    .pipe($.print((path)->"dist:html(2) "+path))
    .pipe($.size(title:'dist:html(2)'))

gulp.task \dist:images, ->
  gulp.src("app/images/**/*")
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.print((path)->"dist:images(1) "+path))
    .pipe($.size(title:'dist:images(1)'))
    .pipe($.cache($.imagemin(
      optimizationLevel: 3
      progressive: true
      interlaced: true
    )))
    .pipe(gulp.dest("dist/images"))
    .pipe($.print((path)->"dist:images(2) "+path))
    .pipe($.size(title:'dist:images(2)'))


gulp.task \dist:cssimages, ->
  gulp.src(mainBowerFiles!)
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.filter("**/*.{png,jpg,jpeg}"))
    .pipe($.print((path)->"dist:cssimages(1) "+path))
    .pipe($.size(title:'dist:cssimages(1)'))
    .pipe($.flatten!)
    .pipe(gulp.dest("dist/styles"))
    .pipe($.print((path)->"dist:cssimages(2) "+path))
    .pipe($.size(title:'dist:cssimages(2)'))

gulp.task \dist:cssfonts, ->
  gulp.src(mainBowerFiles!)
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.filter("**/*.{eot,svg,ttf,woff,woff2}"))
    .pipe($.print((path)->"dist:cssfonts(1) "+path))
    .pipe($.size(title:'dist:cssfonts(1)'))
    .pipe($.size!)
    .pipe($.flatten!)
    .pipe(gulp.dest("dist/styles"))
    .pipe($.print((path)->"dist:cssfonts(2) "+path))
    .pipe($.size(title:'dist:cssfonts(2)'))

gulp.task \dist:refs, ->
  gulp.src(mainBowerFiles!, { base: 'app/' })
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.filter("**/*.{svg,swf}"))
    .pipe($.print((path)->"dist:refs(1) "+path))
    .pipe($.size(title:'dist:refs(1)'))
    .pipe(gulp.dest("dist"))
    .pipe($.print((path)->"dist:refs(2) "+path))
    .pipe($.size(title:'dist:refs(2)'))

gulp.task \dist:refimages, ->
  gulp.src(mainBowerFiles!, { base: 'app/' })
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.filter("**/*.{png,jpg,jpeg}"))
    .pipe($.print((path)->"dist:refimages(1) "+path))
    .pipe($.size(title:'dist:refimages(1)'))
    .pipe($.cache($.imagemin(
      optimizationLevel: 3
      progressive: true
      interlaced: true
    )))
    .pipe(gulp.dest("dist"))
    .pipe($.print((path)->"dist:refimages(2) "+path))
    .pipe($.size(title:'dist:refimages(2)'))

gulp.task \dist:hack1, ->
  gulp.src("app/bower_components/pdfjs-bower/dist/images/**")
    .pipe($.print((path)->"dist:hack1(1) "+path))
    .pipe(gulp.dest("dist/styles/images"))
    .pipe($.print((path)->"dist:hack1(2) "+path))
    .pipe($.size(title:'dist:hack1(2)'))

gulp.task \dist:hack2, ->
  gulp.src("app/scripts/timeline_2.3.1/**")
    .pipe($.print((path)->"dist:hack2(1) "+path))
    .pipe(gulp.dest("dist/scripts/timeline_2.3.1"))
    .pipe($.print((path)->"dist:hack2(2) "+path))
    .pipe($.size(title:'dist:hack2(2)'))

gulp.task \dist:hack3, ->
  gulp.src("app/bower_components/pdfjs-bower/dist/**")
    .pipe($.print((path)->"dist:hack3(1) "+path))
    .pipe(gulp.dest("dist/bower_components/pdfjs-bower/dist"))
    .pipe($.print((path)->"dist:hack3(2) "+path))
    .pipe($.size(title:'dist:hack3(2)'))

gulp.task \dist:hack4, ->
  gulp.src("app/bower_components/semantic-ui/dist/semantic.min.css")
  .pipe($.print((path)->"dist:hack4(1) "+path))
  .pipe(gulp.dest("dist/bower_components/semantic-ui/dist"))
  .pipe($.print((path)->"dist:hack4(2) "+path))
  .pipe($.size(title:'dist:hack4(2)'))

gulp.task \dist:hack5, ->
    gulp.src(".tmp/styles/main.css")
    .pipe($.print((path)->"dist:hack5(1) "+path))
    .pipe(gulp.dest("dist/styles"))
    .pipe($.print((path)->"dist:hack5(2) "+path))
    .pipe($.size(title:'dist:hack5(2)'))

gulp.task \dist:hack6, ->
    gulp.src(".tmp/scripts/main/*-configuration.js")
    .pipe($.print((path)->"dist:hack6(1) "+path))
    .pipe(gulp.dest("dist/scripts/main"))
    .pipe($.print((path)->"dist:hack6(2) "+path))
    .pipe($.size(title:'dist:hack6(2)'))

gulp.task \dist:hacks, <[dist:hack1 dist:hack2 dist:hack3 dist:hack4 dist:hack5 dist:hack6]>

gulp.task \dist:finished, ->
  gulp.src("dist/index.html")
  .pipe($.notify("Distribution finished"))

gulp.task \dist, (cb) ->
  require("run-sequence") \build, <[dist:html dist:refimages dist:refs dist:cssimages dist:cssfonts dist:images dist:hacks]>, \dist:finished, cb
