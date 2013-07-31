module.exports = (grunt) ->
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json')

    coffee: {
      compile:
        expand: true
        cwd: '.'
        src: ['**/*.coffee', '!node_modules/**', '!Gruntfile.coffee']
        dest: '.'
        ext: '.js'
    } # end coffee

    emberTemplates: {
      compile:
        options:
          # Compile templates (file which ends in .handlebars)
          # All template are registered using the filename, regardless of their path
          # If the template should contains a slash, like post/index for example,
          # name it post.index.handlebars
          templateName: (filename) ->
            target = filename.replace(/.*\//i, '').replace('.','/')
            grunt.log.writeln 'register template: '+target
            return target
        files: {'templates.js': '**/*.handlebars'}
    } # end ember_templates

    bower: {
      install: {
        targetDir: 'bower_components'
      }
    }

    watch: {
      ember: {
        files: '**/*.handlebars'
        tasks: ['emberTemplates']
      }
    }
  })

  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-ember-templates'
  grunt.loadNpmTasks 'grunt-bower-task'

  grunt.registerTask 'install', [
    'bower'
  ]

  grunt.registerTask 'default', [
    'coffee'
    'emberTemplates'
  ]

