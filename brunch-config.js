// See http://brunch.io for documentation.
module.exports = {
	files: {
		javascripts: {
			joinTo: {
				'vendor.js': /^(?!cp-styles\/app)/,
				'main.min.js': /^cp-styles\/app/,
				'app.js': /^themes\/^user\/^site\/^haunted\/asset\/^js\/src/,
				'scripts.js': /^node_modules/,
			}
		},
		stylesheets: {
			joinTo: {
				'common.min.css': [
					'cp-styles/app/styles/main.scss',
					'cp-styles/app/styles/legacy/legacy.less',
					'cp-styles/app/styles/css.css',
				],
				'eecms-debug.min.css': [
					'cp-styles/app/styles/debugger.scss'
				],
				'main.min.css': [
					'themes/user/site/haunted/asset/style/scss/main.scss'
				]
			}
		}
	},

	paths: {
		public: 'themes/user/site/haunted/asset/dist',
		watched: [
			'themes/user/site/haunted/asset/style',
			'themes/user/site/haunted/asset/style/scss',
			'themes/user/site/haunted/asset/js/src'
		]
	},

	plugins: {
		// babel: {
		//     presets: ['latest']
		// },
		sass: {
			modules: true,
			options: {
				includePaths: [
					'node_modules/accoutrement/sass',
					'node_modules/gerillass/scss',
					'node_modules/swiper',
					'node_modules/@waaark/luge'
				]
			}
		},
		brunchTypescript: {
			removeComments: true
		},
		cleancss: {
			// inline: ['all'],
			keepSpecialComments: 0,
			removeEmpty: true,
			level: 1
		}
	},
	npm: {
    enabled: true,
    globals: {
      $: 'jquery',
      jQuery: 'jquery'
    }
  }
};
