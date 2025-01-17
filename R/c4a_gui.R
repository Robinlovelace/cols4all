def_n = function(npref = NA, type, series, tab_nmin, tab_nmax) {

	nmin = suppressWarnings(min(tab_nmin[series, type], na.rm = TRUE))
	nmax = suppressWarnings(max(tab_nmax[series, type], na.rm = TRUE))
	if (is.infinite(nmin)) return(NULL)

	if (is.na(npref)) npref = switch(type, cat = 7, seq = 7, div = 9, 3)
	if (is.infinite(nmax)) nmax = 15
	if (nmin < 2) nmin = 2

	n = if (is.infinite(nmin)) {
		npref # should not happen or else throw a message elsewhere
	} else if (nmin < npref && nmax > npref) {
		npref
	} else if (is.infinite(nmax)) {
		nmin
	} else {
		nmax
	}
	list(n = n, nmin = nmin, nmax = nmax)
}



#' @rdname c4a_gui
#' @name c4a_gui
#' @export
c4a_gui = function(type = "cat", n = NA, series = c("misc", "brewer", "scico", "hcl", "tol", "viridis", "c4a")) {
	if (!requireNamespace("shiny")) stop("Please install shiny")
	if (!requireNamespace("shinyjs")) stop("Please install shinyjs")
	if (!requireNamespace("kableExtra")) stop("Please install kableExtra")

	shiny::addResourcePath(prefix = "imgResources", directoryPath = system.file("img", package = "cols4all"))

	#############################
	## Catelogue tab
	#############################

	z = .C4A$z

	z = z[order(z$fullname), ]

	tps = unname(.C4A$types)

	tab_nmin = tapply(z$nmin, INDEX = list(z$series, factor(z$type, levels = tps)), FUN = min)
	tab_nmax = tapply(z$nmax, INDEX = list(z$series, factor(z$type, levels = tps)), FUN = max)
	tab_k = as.data.frame(tapply(z$nmin, INDEX = list(z$series, factor(z$type, levels = tps)), FUN = length))
	tab_k$series = rownames(tab_k)
	tab_k = tab_k[, c("series", tps)]


	allseries = sort(unique(z$series))
	if (series[1] == "all") {
		series = allseries
	} else {
		if (!all(series %in% allseries)) message("These series do not exist: \"", paste(setdiff(series, allseries), collapse = "\", \""), "\"")
		series = intersect(series, allseries)
	}
	if (!length(series)) {
		message("No palette series to show. Either restart c4a_gui with different parameters, add series with c4a_palettes_add, or import data with c4a_sysdata_import")
		return(invisible(NULL))
	}

	types_available = names(which(apply(tab_nmin, MARGIN = 2, function(x)any(!is.na(x)))))

	stopifnot(length(types_available) > 0L)
	if (!(type %in% types_available)) {
		type = types_available[1]
	}


	ns = def_n(npref = n, type, series, tab_nmin, tab_nmax)

	types = .C4A$types

	types1 = .C4A$types1
	types2 = .C4A$types2

	if (nchar(type) == 3) {
		type1 = type
		type2 = if (type %in% names(types2)) unname(types2[[type]][1]) else ""
	} else {
		type2 = type
		type1 = substr(type, 1, 3)
	}
	type12 = paste0(type1, type2)

	init_pal_list = z$fullname[z$type == type12]


	#############################
	## Contrast tab
	#############################

	palette = z$fullname[1]

	x = c4a_info(palette)

	n_init = x$ndef
	pal_init = c(c4a(palette, n = n_init), "#ffffff", "#000000")


	getNames = function(p) {
		lapply(p, function(pi) {
			shiny::HTML(paste0("<div style='font-size:2em;line-height:0.5em;height:0.5em;color:", pi, "'>&#9632;</div>"))
		})
	}





	ui = shiny::fluidPage(
		shinyjs::useShinyjs(),
		shiny::tags$head(shiny::includeCSS(system.file("www/light.css", package = "cols4all"))),
		shiny::tags$head(shiny::includeCSS(system.file("www/dark.css", package = "cols4all"))),
		shiny::tags$head(shiny::includeCSS(system.file("www/misc.css", package = "cols4all"))),
		shiny::absolutePanel(
			top = 25,
			right = 40,
			width = 90,
			shiny::checkboxInput("dark", "Dark mode", value = FALSE)),
		shiny::absolutePanel(
			top = 10,
			right = 10,
			width = 20,
			shiny::actionButton("info", "", shiny::icon("info"),
								style="color: #fff; background-color: #337ab7; border-color: #2e6da4")
		),
		shiny::tabsetPanel(
			id="inTabset",
			shiny::tabPanel("Overview",
							value = "tab_catel",
					 shiny::fluidRow(
					 	shiny::column(width = 3,
					 				  shiny::img(src = "imgResources/cols4all_logo.png", height="200", align = "center", 'vertical-align' = "center")),
					 	shiny::column(width = 9,
					 				  shiny::fluidRow(
					 				  	shiny::column(width = 4,
		 				  				  shiny::radioButtons("type1", "Palette Type", choices = types1, selected = type1),
		 				  				  shiny::conditionalPanel(
		 				  				  	condition = "input.type1 == 'biv'",
		 				  				  	shiny::selectizeInput("type2", "Subtype", choices = types2[["biv"]], selected = type2))),
					 				  	shiny::column(width = 4,
					 				  				  shiny::conditionalPanel(
					 				  				  	condition = "input.type1 != 'biv'",
					 				  				  	shiny::sliderInput("n", "Number of colors", min = ns$nmin, max = ns$nmax, value = ns$n, ticks = FALSE)),
					 				  				  shiny::conditionalPanel(
					 				  				  	condition = "input.type1 == 'biv'",
					 				  				  	shiny::fluidRow(
					 				  				  		shiny::column(6,
					 				  				  					  shiny::sliderInput("nbiv", "Number of columns", min = 3, max = 7, value = 3, ticks = FALSE)),
					 				  				  		shiny::column(6,
					 				  				  					  shinyjs::disabled(shiny::sliderInput("mbiv", "Number of rows", min = 3, max = 7, value = 3, ticks = FALSE))))),
					 				  				  shiny::checkboxInput("na", "Color for missing values", value = FALSE),
					 				  				  shiny::conditionalPanel(
					 				  				  	condition = "input.type1 == 'seq' || input.type1 == 'div'",
					 				  				  	shiny::fluidRow(
					 				  				  		shiny::column(4,
					 				  				  					  #shiny::br(),
					 				  				  					  shiny::radioButtons("auto_range", label = "Range", choices = c("Automatic", "Manual"), selected = "Automatic")),
					 				  				  		shiny::conditionalPanel(
					 				  				  			condition = "input.auto_range == 'Manual'",
					 				  				  			shiny::column(8,
					 				  				  						  shiny::div(style = "font-size:0;margin-bottom:-10px", shiny::sliderInput("range", "", min = 0, max = 1, value = c(0,1), step = .05)),
					 				  		shiny::uiOutput("range_info"))
					 				  		)
					 				  ))),
					 				  shiny::column(width = 4,
					 				  			  shiny::radioButtons("cvd", "Color vision", choices = c(Normal = "none", 'Deutan (red-green blind)' = "deutan", 'Protan (also red-green blind)' = "protan", 'Tritan (blue-yellow)' = "tritan"), selected = "none")
					 				  )),
					 	shiny::fluidRow(
					 		shiny::column(width = 4,
					 					  shiny::div(style = "margin-bottom: 5px;", shiny::strong("Palette series")),
					 					  shiny::div(class = 'multicol',
					 					  		   shiny::checkboxGroupInput("series", label = "", choices = allseries, selected = series, inline = FALSE)),
					 					  shiny::fluidRow(
					 					  	shiny::column(12, align="right",
					 					  				  shiny::actionButton("all", label = "All"),
					 					  				  shiny::actionButton("none", label = "None"),
					 					  				  shiny::actionButton("overview", label = "Overview")))),
					 		shiny::column(width = 4,
					 					  shiny::fluidRow(
					 					  	shiny::column(6,
					 					  				  shiny::radioButtons("format", "Text format", choices = c("Hex" = "hex", "RGB" = "RGB", "HCL" = "HCL"), inline = FALSE)
					 					  	),
					 					  	shiny::column(6,
					 					  				  shiny::radioButtons("textcol", "Text color", choices = c("Hide text" = "same", Black = "#000000", White = "#FFFFFF", Automatic = "auto"), inline = FALSE)	))
					 		),
					 		shiny::column(width = 4,
					 					  shiny::selectizeInput("sort", "Sort", choices = structure(c("name", "rank"), names = c("Name", .C4A$labels["cbfriendly"])), selected = "name"),
					 					  shiny::checkboxInput("sortRev", "Reverse sorting", value = FALSE),
					 					  shiny::checkboxInput("advanced", "Show scores", value = FALSE)
					 		)))),

					 shiny::fluidRow(
					 	shiny::column(
					 		width = 12,
					 		shiny::tableOutput("show"))
					 )
			),
			shiny::tabPanel("Color Blind Friendliness & Hues",
							value = "tab_cvd",
							shiny::fluidRow(
								shiny::column(width = 12,
											  shiny::selectizeInput("cbfPal", "Palette", choices = z$fullname),
											  shiny::markdown("<br/><br/>
					  #### **Color blindness simulation**"),
											  shiny::plotOutput("cbfSim", "Palette simulation", width = "800px", height = "150px"))),
							shiny::fluidRow(
								shiny::column(width = 4, shiny::markdown("<br/><br/>
					  #### **Confusion lines**")),
								shiny::column(width = 6, shiny::markdown("<br/><br/>
					  #### **Distance matrices**"))),
							shiny::fluidRow(shiny::column(width = 12, shiny::markdown("Normal color vision"))),
							shiny::fluidRow(shiny::column(width = 4, shiny::plotOutput("cbfRGB1", "Confusion lines1", width = "375px", height = "375px")),
											shiny::column(width = 6, shiny::plotOutput("disttable1", height = "375px", width = "500px", click = "disttable1_click")),
											shiny::column(width = 2, shiny::plotOutput("cbf_ex1", height = "375px", width = "150px"))),
							shiny::fluidRow(shiny::column(width = 12, shiny::markdown("<br/><br/>Deutan (red-green blind)"))),
							shiny::fluidRow(shiny::column(width = 4, shiny::plotOutput("cbfRGB2", "Confusion lines1", width = "375px", height = "375px")),
											shiny::column(width = 6, shiny::plotOutput("disttable2", height = "375px", width = "500px", click = "disttable2_click")),
											shiny::column(width = 2, shiny::plotOutput("cbf_ex2", height = "375px", width = "150px"))),
							shiny::fluidRow(shiny::column(width = 12, shiny::markdown("<br/><br/>Protan (also red-green blind)"))),
							shiny::fluidRow(shiny::column(width = 4, shiny::plotOutput("cbfRGB3", "Confusion lines1", width = "375px", height = "375px")),
											shiny::column(width = 6, shiny::plotOutput("disttable3", height = "375px", width = "500px", click = "disttable3_click")),
											shiny::column(width = 2, shiny::plotOutput("cbf_ex3", height = "375px", width = "150px"))),
							shiny::fluidRow(shiny::column(width = 12, shiny::markdown("<br/><br/>Tritan (blue-yellow)"))),
							shiny::fluidRow(shiny::column(width = 4, shiny::plotOutput("cbfRGB4", "Confusion lines1", width = "375px", height = "375px")),
											shiny::column(width = 6, shiny::plotOutput("disttable4", height = "375px", width = "500px", click = "disttable4_click")),
											shiny::column(width = 2, shiny::plotOutput("cbf_ex4", height = "375px", width = "150px")))),
			shiny::tabPanel("Vividness & Harmony",
							value = "tab_cl",
							shiny::fluidRow(
								shiny::column(width = 12,
											  shiny::markdown("<br/><br/>
					  #### **Vividness & Harmony**

							How bright (luminance) and vivid (chroma) are the colors in a palette?<br/><br/>"),
											  shiny::selectizeInput("CLPal", "Palette", choices = z$fullname),
											  shiny::markdown("<br/><br/>
					  #### **Chroma-Luminance plot**"),
								shiny::plotOutput("CLplot", "CL plot", width = "600px", height = "600px")
								))),
			shiny::tabPanel("Contrast",
							value = "tab_cont",
				 	shiny::fluidRow(
				 		shiny::column(width = 12,
				 					  shiny::markdown("<br/><br/>
					  #### **Equiluminance**

							Colors that are equally bright (luminant) may cause 'wobbly' borders when drawn next to each other. Using border lines solves this potential problem.<br/><br/>"),
				 					  shiny::selectizeInput("contrastPal", "Palette", choices = z$fullname),
				 					  shiny::markdown("#### **Contrast ratio**"),
				 					  shiny::plotOutput("table", height = "300px", width = "400px", click = "table_click"),
				 					  shiny::markdown("A low contrast ratio means that colors are about equally bright (luminant)"),)),

				 	shiny::fluidRow(
				 		shiny::column(width = 3,
				 					  shiny::radioButtons("chart", "Example chart", c("Choropleth", "Barchart"), "Choropleth", inline = FALSE),
			 					  	  shiny::sliderInput("lwd", "Line Width", min = 0, max = 3, step = 1, value = 0),
				 					  shiny::selectInput("borders", "Borders", choices = c("black", "white"), selected = "black")),
				 		shiny::column(
				 			width = 9,
				 			shiny::plotOutput("ex", height = "300px", width = "600px")
				 		)

				 	),
				 	shiny::fluidRow(
				 		shiny::column(width = 12,
				 					  shiny::markdown("#### **Optical Illusion Art** "),
				 					  shiny::plotOutput("ex_plus", height = "703", width = "900"),
				 					  shiny::markdown("_Plus Reversed_ by Richard Anuszkiewicz (1960)")
				 		)
					)

			),
			shiny::tabPanel("3D Blues",
							value = "tab_floating",
							shiny::fluidRow(
								shiny::column(width = 12,
											  shiny::selectizeInput("floatPal", "Palette", choices = z$fullname),
											  shiny::markdown("<br/><br/>
					  #### **Chromostereopsis**

							Do you see een 3D effect? If not check 'Use original colors' below. Chromostereopsis is a visual illusion that happens when a blue color is shown next to a red color with a dark background."))),

							shiny::fluidRow(
								shiny::column(width = 8,
											  shiny::plotOutput("floating_rings", height = 550, width = 550),
											  shiny::markdown("<br/><br/>[_Visual illusion by Michael Bach_](https://michaelbach.de/ot/col-chromostereopsis/)"),
											  shiny::checkboxInput("float_original", "Use original colors", value = FALSE),
											  shiny::checkboxInput("float_rev", "Reverse colors", value = FALSE)),
								shiny::column(width = 4,
											  shiny::plotOutput("float_letters", "Float letter", height = 80, width = 300),
											  shiny::uiOutput("float_selection"),
											  shiny::plotOutput("float_letters_AB", "Float letter", height = 150, width = 300)
											  ))),




			shiny::tabPanel("Application",
							value = "tab_app",
				shiny::fluidRow(
					shiny::column(width = 12,
								  shiny::selectizeInput("APPPal", "Palette", choices = z$fullname))),
				shiny::fluidRow(
				  	shiny::column(width = 4, shiny::sliderInput("MAPlwd", "Line Width", min = 0, max = 3, step = 1, value = 1)),
				  	shiny::column(width = 4, shiny::selectInput("MAPborders", "Borders", choices = c("black", "white"), selected = "black")),
					shiny::column(width = 4, shiny::radioButtons("MAPdist", "Color distribution", choices = c(Random = "random", Gradient = "gradient"), selected = "random"))),
				shiny::fluidRow(
					shiny::column(width = 12, shiny::plotOutput("MAPplot", "Map", width = 800, height = 400))),
				shiny::fluidRow(
					shiny::column(width = 4, shiny::sliderInput("DOTlwd", "Line Width", min = 0, max = 3, step = 1, value = 1)),
					shiny::column(width = 4, shiny::selectInput("DOTborders", "Borders", choices = c("black", "white"), selected = "black")),
					shiny::column(width = 4, shiny::radioButtons("DOTdist", "Color distribution", choices = c(Random = "random", Concentric = "concentric"), selected = "random"))),
				shiny::fluidRow(
					shiny::column(width = 12, shiny::plotOutput("DOTplot", "Scatter plot", width = 800, height = 400))),
				shiny::fluidRow(
					shiny::column(width = 12, shiny::plotOutput("TXTplot1", "Text", width = 800, height = 120))),
				shiny::fluidRow(
					shiny::column(width = 12, shiny::plotOutput("TXTplot2", "Text", width = 800, height = 120)))
		)
	))


	#################################################################################################################################################################################
	#################################################################################################################################################################################
	#################################################################################################################################################################################
	#################################################################################################################################################################################
	#################################################################################################################################################################################
	##############################################################                                             ######################################################################
	##############################################################           Server                            ######################################################################
	##############################################################                                             ######################################################################
	#################################################################################################################################################################################
	#################################################################################################################################################################################
	#################################################################################################################################################################################
	#################################################################################################################################################################################
	#################################################################################################################################################################################
	#################################################################################################################################################################################


	server = function(input, output, session) {
		#############################
		## Catelogue tab
		#############################

		series_d = shiny::debounce(shiny::reactive(input$series), 300)

		get_type12 = shiny::reactive({
			type1 = input$type1
			type12 = if (type1 %in% names(types2)) {
				input$type2
			} else {
				type1
			}
		})


		tab_vals = shiny::reactiveValues(pal = c(pal_init, "#FFFFFF", "#000000"),
										 pal_name = palette,
										 n = n_init,
										 col1 = pal_init[1], col2 = pal_init[2],
										 type = type12,
										 cvd = "none")



		shiny::observeEvent(input$all, {
			shiny::freezeReactiveValue(input, "series")
			shiny::updateCheckboxGroupInput(session, "series", selected = allseries)
		})

		shiny::observeEvent(input$none, {
			shiny::freezeReactiveValue(input, "series")
			shiny::updateCheckboxGroupInput(session, "series", selected = character())
		})

		shiny::observeEvent(get_cols(), {
			cols = get_cols()
			sort = shiny::isolate(input$sort)
			shiny::freezeReactiveValue(input, "sort")
			sortNew = if (sort %in% cols) sort else "name"
			shiny::updateSelectInput(session, "sort", choices  = cols,selected = sortNew)
		})

		shiny::observeEvent(input$dark, {

			if ( ! input$dark ) {
				shinyjs::removeClass(selector = "body", class = "dark")
			} else {
				shinyjs::addClass(selector = "body", class = "dark")
			}

		})


		shiny::observeEvent(get_type12(), {
			type = get_type12()

			if (!(type %in% types_available)) return(NULL)
			if (type %in% c("cat", "seq", "div")) {
				series = series_d()
				if (is.null(series)) return(NULL)
				ns =  def_n(npref = input$n, type, series, tab_nmin, tab_nmax)
				shiny::freezeReactiveValue(input, "n")
				shiny::updateSliderInput(session, "n", min = ns$nmin, max = ns$nmax, value = ns$n)
			} else {
				ndef = unname(.C4A$ndef[type])

				mdef = unname(.C4A$mdef[type])
				if (is.na(mdef)) {
					shinyjs::disable("mbiv")
				} else {
					shinyjs::enable("mbiv")
				}
				nmin = if (type == "bivd") 3 else 2
				nstep = if (type == "bivd") 2 else 1

				shiny::freezeReactiveValue(input, "nbiv")
				shiny::freezeReactiveValue(input, "mbiv")
				shiny::updateSliderInput(session, "nbiv", value = ndef, min = nmin, step = nstep)
				shiny::updateSliderInput(session, "mbiv", value = mdef, min = nmin, step = nstep)
			}
			# print("/+++++++++")
		})


		shiny::observeEvent(series_d(), {
			type = get_type12()

			if (!(type %in% c("cat", "seq", "div"))) return(NULL)

			series = series_d()

			if (is.null(series)) return(NULL)
			ns =  def_n(npref = input$n, type, series, tab_nmin, tab_nmax)
			# print("-------------")
			# print(ns)
			if (is.null(ns)) return(NULL)
			shiny::freezeReactiveValue(input, "n")
			shiny::updateSliderInput(session, "n", min = ns$nmin, max = ns$nmax, value = ns$n)
			# print("/-------------")
		})

		shiny::observeEvent(input$overview, {
			type = get_type12()#rv$type12
			title = paste0("Overview of palettes per series of type ", type)
			shiny::showModal(shiny::modalDialog(title = "Number of palettes per series (rows) and type (columns)",
												shiny::renderTable(tab_k, na = "", striped = TRUE, hover = TRUE, bordered = TRUE),
												shiny::div(style="font-size: 75%;", shiny::renderTable(.C4A$type_info)),
												footer = shiny::modalButton("Close"),
												style = "color: #000000;"))
		})

		get_cols = shiny::reactive({
			type = get_type12()
			res = table_columns(type, input$advanced)
			anyD = duplicated(res$ql)

			structure(c("name", res$qn[!anyD]), names = c("Name", res$ql[!anyD]))
		})



		get_values = shiny::reactive({
			if (input$sort == "") return(NULL)

			type = get_type12()
			n = input$n
			if (is.null(n)) return(NULL)
			lst = list(n = n,
				 nbiv = input$nbiv,
				 mbiv = input$mbiv,
				 type = type,
				 cvd = input$cvd,
				 sort = input$sort,
				 sortRev = input$sortRev,
				 series = series_d(),
				 show.scores = input$advanced,
				 columns = if (n > 16) 12 else n,
				 na = input$na,
				 range = if (input$auto_range == "Automatic") NA else input$range,
				 textcol = input$textcol,
				 format = input$format)

			if (substr(type, 1, 3) == "biv") {
				m = n
			} else {
				m = 1
			}

			sel = z$type == type &
				z$series %in% lst$series &
				lst$n <= z$nmax
			if (!any(sel)) {
				lst$pal_names = character(0)
			} else {
				lst$pal_names = sort(z$fullname[sel])
			}

			lst
		})
		#get_values_d = shiny::debounce(get_values, 300)


		shiny::observeEvent(input$nbiv, {
			nbiv = input$nbiv
			type = get_type12()#rv$type12
			if (type == "bivs") {
				shiny::freezeReactiveValue(input, "mbiv")
				shiny::updateSliderInput(session, "mbiv", value = nbiv)
			}

		})

		# shiny::observe({
		# 	n = input$n
		# 	ac = input$auto_range
		# 	type = input$type
		#
		# 	if (type == "cat") return(NULL)
		# 	if (ac != "Manual") {
		# 		shiny::freezeReactiveValue(input, "range")
		# 		shinyjs::disable("range")
		# 		if (ac == "Maximum") {
		# 			rng = c(0, 1)
		# 		} else {
		# 			fun = paste0("default_range_", type)
		# 			rng = do.call(fun, list(k = n))
		# 		}
		# 		shinyjs::disable("range")
		# 		shiny::updateSliderInput(session, "range", value = c(rng[1], rng[2]))
		# 	} else {
		# 		shinyjs::enable("range")
		# 	}
		# })

		output$range_info = shiny::renderUI({
			#if (input$type == "div") shiny::div(style="text-align:left;", shiny::tagList("middle", shiny::span(stype = "float:right;", "each side"))) else ""
			type = get_type12()#rv$type12


			if (type == "div") {
				shiny::HTML("<div style='font-size:70%; color:#111111; text-align:left;'>Middle<span style='float:right;'>Both sides</span></div>")
			} else {
				shiny::HTML("<div style='font-size:70%; color:#111111; text-align:left;'>Left<span style='float:right;'>Right</span></div>")
			}
		})

		shiny::observe({
			values = get_values()
			pals = values$pal_names
			#n = values$n

			if (length(pals)) {
				selPal2 = if (length(tab_vals$pal_name) && tab_vals$pal_name %in% pals) tab_vals$pal_name else pals[1]
				shiny::updateSelectizeInput(session, "cbfPal", choices = pals, selected = selPal2)
				shiny::updateSelectizeInput(session, "CLPal", choices = pals, selected = selPal2)
				shiny::updateSelectizeInput(session, "contrastPal", choices = pals, selected = selPal2)
				shiny::updateSelectizeInput(session, "floatPal", choices = pals, selected = selPal2)
				shiny::updateSelectizeInput(session, "APPPal", choices = pals, selected = selPal2)
				shinyjs::enable("cbfPal")
				shinyjs::enable("CLPal")
				shinyjs::enable("contrastPal")
				shinyjs::enable("floatPal")
				shinyjs::enable("APPPal")
			} else {
				shiny::updateSelectizeInput(session, "cbfPal", choices = pals)
				shiny::updateSelectizeInput(session, "CLPal", choices = pals)
				shiny::updateSelectizeInput(session, "contrastPal", choices = pals)
				shiny::updateSelectizeInput(session, "floatPal", choices = pals)
				shiny::updateSelectizeInput(session, "APPPal", choices = pals)

				shinyjs::disable("cbfPal")
				shinyjs::disable("CLPal")
				shinyjs::disable("contrastPal")
				shinyjs::disable("floatPal")
				shinyjs::disable("APPPal")
			}
		})

		output$show = function() {

			values = get_values()#_d()
			if (is.null(values) || is.null(values$series)) {
				tab = NULL
			} else {
				# Create a Progress object
				progress <- shiny::Progress$new()
				# Make sure it closes when we exit this reactive, even if there's an error
				on.exit(progress$close())

				progress$set(message = "Colors in progress...", value = 0)

				sort = paste0({if (values$sortRev) "-" else ""}, values$sort)

				if (substr(values$type, 1, 3) == "biv") {
					tab = c4a_table(n = values$nbiv, m = values$mbiv, cvd.sim = values$cvd, sort = sort, columns = values$columns, type = values$type, show.scores = values$show.scores, series = values$series, range = values$range, include.na = values$na, text.col = values$textcol, text.format = values$format, verbose = FALSE)
				} else {
					tab = c4a_table(n = values$n, cvd.sim = values$cvd, sort = sort, columns = values$columns, type = values$type, show.scores = values$show.scores, series = values$series, range = values$range, include.na = values$na, text.col = values$textcol, text.format = values$format, verbose = FALSE)
				}
			}

			if (is.null(tab)) {
				kableExtra::kbl(data.frame("No palettes found. Please change the selection."), col.names = " ")
			} else {
				tab
			}
		}

		#############################
		## CBF tab
		#############################

		output$cbfSim = shiny::renderPlot({
			if (!length(tab_vals$pal)) return(NULL)

			pal = tab_vals$pal
			c4a_plot_cvd(pal, dark = input$dark)
		})

		output$cbfRGB1 = shiny::renderPlot({
			if (!length(tab_vals$pal)) return(NULL)

			pal = tab_vals$pal
			c4a_plot_confusion_lines(pal, cvd = "none", dark = input$dark)
		})

		output$cbfRGB2 = shiny::renderPlot({
			if (!length(tab_vals$pal)) return(NULL)

			pal = tab_vals$pal
			c4a_plot_confusion_lines(pal, cvd = "deutan", dark = input$dark)
		})

		output$cbfRGB3 = shiny::renderPlot({
			if (!length(tab_vals$pal)) return(NULL)

			pal = tab_vals$pal
			c4a_plot_confusion_lines(pal, cvd = "protan", dark = input$dark)
		})

		output$cbfRGB4 = shiny::renderPlot({
			if (!length(tab_vals$pal)) return(NULL)

			pal = tab_vals$pal
			c4a_plot_confusion_lines(pal, cvd = "tritan", dark = input$dark)
		})

		output$disttable1 = shiny::renderPlot({
			if (!length(tab_vals$pal)) return(NULL)

			pal = tab_vals$pal
			col1 = tab_vals$col1
			col2 = tab_vals$col2
			id1 = which(col1 == pal)
			id2 = which(col2 == pal)

			c4a_plot_dist_matrix(pal, cvd = "none", id1 = id1, id2 = id2, dark = input$dark)
		})

		output$disttable2 = shiny::renderPlot({
			if (!length(tab_vals$pal)) return(NULL)

			pal = tab_vals$pal
			col1 = tab_vals$col1
			col2 = tab_vals$col2
			id1 = which(col1 == pal)
			id2 = which(col2 == pal)

			c4a_plot_dist_matrix(pal, cvd = "deutan", id1 = id1, id2 = id2, dark = input$dark)
		})

		output$disttable3 = shiny::renderPlot({
			if (!length(tab_vals$pal)) return(NULL)

			pal = tab_vals$pal
			col1 = tab_vals$col1
			col2 = tab_vals$col2
			id1 = which(col1 == pal)
			id2 = which(col2 == pal)

			c4a_plot_dist_matrix(pal, cvd = "protan", id1 = id1, id2 = id2, dark = input$dark)
		})

		output$disttable4 = shiny::renderPlot({
			if (!length(tab_vals$pal)) return(NULL)

			pal = tab_vals$pal
			col1 = tab_vals$col1
			col2 = tab_vals$col2
			id1 = which(col1 == pal)
			id2 = which(col2 == pal)

			c4a_plot_dist_matrix(pal, cvd = "tritan", id1 = id1, id2 = id2, dark = input$dark)
		})

		cfb_map = function(cols, cvd) {
			if (!length(cols)) return(NULL)

			hcl = get_hcl_matrix(cols)

			cols_cvd = sim_cvd(cols, cvd)

			borders = ifelse(mean(hcl[,3]>=50), "#000000", "#FFFFFF")

			c4a_plot_map(col1 = cols_cvd[1], col2 = cols_cvd[2], borders = borders, lwd = 1, crop = TRUE, dark = input$dark)
		}


		output$cbf_ex1 = shiny::renderPlot({
			if (!length(tab_vals$col1)) return(NULL)
			cfb_map(c(tab_vals$col1, tab_vals$col2), "none")
		})
		output$cbf_ex2 = shiny::renderPlot({
			if (!length(tab_vals$col1)) return(NULL)
			cfb_map(c(tab_vals$col1, tab_vals$col2), "deutan")
		})
		output$cbf_ex3 = shiny::renderPlot({
			if (!length(tab_vals$col1)) return(NULL)
			cfb_map(c(tab_vals$col1, tab_vals$col2), "protan")
		})
		output$cbf_ex4 = shiny::renderPlot({
			if (!length(tab_vals$col1)) return(NULL)
			cfb_map(c(tab_vals$col1, tab_vals$col2), "tritan")
		})


		#############################
		## Harmony tab
		#############################



		output$CLplot = shiny::renderPlot({
			pal = tab_vals$pal

			if (!length(pal)) return(NULL)

			type = tab_vals$type

			c4a_plot_CL(pal, Lrange = (type == type), dark = input$dark)
		})


		#############################
		## Contrast tab
		#############################

		update_reactive = function(pal_name, pal_nr) {
			pal = pal_name
			if (pal == "") {
				tab_vals$pal = character(0)
				tab_vals$pal_name = character(0)
				tab_vals$palBW = character(0)
				tab_vals$col1 = character(0)
				tab_vals$col2 = character(0)
				tab_vals$type = character(0)

			} else {
				x = c4a_info(pal)
				n_init = x$ndef

				cols = as.vector(c4a(x$fullname, n = n_init))
				colsBW = c(cols, "#FFFFFF", "#000000")

				tab_vals$pal = cols
				tab_vals$pal_name = pal_name

				tab_vals$palBW = colsBW

				tab_vals$col1 = cols[1]
				tab_vals$col2 = cols[2]
				tab_vals$type = x$type
			}
			if (pal_nr != 1) shiny::updateSelectizeInput(session, "cbfPal", selected = pal)
			if (pal_nr != 2) shiny::updateSelectizeInput(session, "CLPal", selected = pal)
			if (pal_nr != 3) shiny::updateSelectizeInput(session, "contrastPal", selected = pal)
			if (pal_nr != 4) shiny::updateSelectizeInput(session, "floatPal", selected = pal)
			if (pal_nr != 5) shiny::updateSelectizeInput(session, "APPPal", selected = pal)

		}


		shiny::observeEvent(input$cbfPal, update_reactive(input$cbfPal, 1))
		shiny::observeEvent(input$CLPal, update_reactive(input$CLPal, 2))
		shiny::observeEvent(input$contrastPal, update_reactive(input$contrastPal, 3))
		shiny::observeEvent(input$floatPal, update_reactive(input$floatPal, 4))
		shiny::observeEvent(input$APPPal, update_reactive(input$APPPal, 5))


		output$ex_plus = shiny::renderPlot({
			col1 = tab_vals$col1
			col2 = tab_vals$col2

			if (!length(col1)) return(NULL)
			borders = input$borders
			lwd = input$lwd

			c4a_plot_Plus_Reversed(col1, col2, orientation = "landscape", borders = borders, lwd = lwd)
		})

		output$ex = shiny::renderPlot({
			col1 = tab_vals$col1
			col2 = tab_vals$col2

			if (!length(col1)) return(NULL)

			borders = input$borders
			lwd = input$lwd
			if (input$chart == "Barchart") {
				c4a_plot_bars(col1 = col1, col2 = col2, borders = borders, lwd = lwd, dark = input$dark)
			} else {
				c4a_plot_map(col1 = col1, col2 = col2, borders = borders, lwd = lwd, dark = input$dark)
			}
		})

		output$table = shiny::renderPlot({
			col1 = tab_vals$col1
			col2 = tab_vals$col2
			pal = tab_vals$palBW

			if (!length(col1)) return(NULL)

			id1 = which(col1 == pal)
			id2 = which(col2 == pal)
			c4a_plot_CR_matrix(pal, id1 = id1, id2 = id2, dark = input$dark)
		})




		get_click_id = function(pal, x, y) {
			n = length(pal)

			brks_x = seq(0.04, 0.76, length.out = n + 2)
			brks_y = seq(0, 1, length.out = n + 2)

			x_id = as.integer(cut(x, breaks = brks_x)) - 1
			y_id = n + 1 - as.integer(cut(y, breaks = brks_y))

			if (!is.na(x_id) && (x_id < 1 || x_id > n)) x_id = NA
			if (!is.na(y_id) && (y_id < 1 || y_id > n)) y_id = NA

			list(x = x_id, y = y_id)
		}

		observeEvent(input$disttable1_click, {
			pal = tab_vals$pal
			if (!length(pal)) return(NULL)

			ids = get_click_id(pal, input$disttable1_click$x, input$disttable1_click$y)

			if (!is.na(ids$x)) tab_vals$col2 = pal[ids$x]
			if (!is.na(ids$y)) tab_vals$col1 = pal[ids$y]
		})

		observeEvent(input$disttable2_click, {
			pal = tab_vals$pal
			if (!length(pal)) return(NULL)

			ids = get_click_id(pal, input$disttable2_click$x, input$disttable2_click$y)

			if (!is.na(ids$x)) tab_vals$col2 = pal[ids$x]
			if (!is.na(ids$y)) tab_vals$col1 = pal[ids$y]

		})

		observeEvent(input$disttable3_click, {
			pal = tab_vals$pal
			if (!length(pal)) return(NULL)

			ids = get_click_id(pal, input$disttable3_click$x, input$disttable3_click$y)

			if (!is.na(ids$x)) tab_vals$col2 = pal[ids$x]
			if (!is.na(ids$y)) tab_vals$col1 = pal[ids$y]
		})

		observeEvent(input$disttable4_click, {
			pal = tab_vals$pal
			if (!length(pal)) return(NULL)

			ids = get_click_id(pal, input$disttable4_click$x, input$disttable4_click$y)

			if (!is.na(ids$x)) tab_vals$col2 = pal[ids$x]
			if (!is.na(ids$y)) tab_vals$col1 = pal[ids$y]
		})


		observeEvent(input$table_click, {
			pal = tab_vals$palBW
			if (!length(pal)) return(NULL)

			ids = get_click_id(pal, input$table_click$x, input$table_click$y)

			if (!is.na(ids$x)) tab_vals$col2 = pal[ids$x]
			if (!is.na(ids$y)) tab_vals$col1 = pal[ids$y]
		})




		##############################
		## Floating tab
		##############################



		output$float_letters = shiny::renderPlot({
			pal = tab_vals$pal
			if (!length(pal)) return(NULL)

			c4a_plot_text(pal, dark = input$dark, size = 1.25, frame = TRUE)
		})

		output$float_selection = shiny::renderUI({
			pal = tab_vals$pal
			if (!length(pal)) return(NULL)

			b = approx_blues(pal)
			r = approx_reds(pal)
			ids = c(which.max(b)[1], which.max(r)[1])


			if (max(b) > .C4A$Blues && max(r) > 1) {
				btext = paste0("Color ", c(LETTERS, letters)[ids[1]], " is very blue, so a 3D effect will likely occur (at least, with a dark background). We will plot it next to a red color in the palette, color ", c(LETTERS, letters)[ids[2]])
			} else if (max(b) > 1 && max(r) > 1) {
				btext = paste0("Color ", c(LETTERS, letters)[ids[1]], " is blue, so a 3D effect might  occur (at least with a dark background).  We will plot it next to a red color in the palette, color ", c(LETTERS, letters)[ids[2]])
			} else if (max(b) > 1 && max(r) <= 1) {
				btext = paste0("The palette contains blue color(s), e.g. color ", c(LETTERS, letters)[ids[1]]," but no red(dish) color, so a 3D effect will probably not occur.")
			} else {
				btext = "This palette does not contain any blue color, so a 3D effect does not happen."
			}


			shiny::tagList(
				shiny::markdown(paste(btext)),
				shiny::selectInput("float_col1", "Color 1", choices = c(LETTERS, letters)[1:length(pal)], selected = c(LETTERS, letters)[ids[1]]),
				shiny::selectInput("float_col2", "Color 2", choices = c(LETTERS, letters)[1:length(pal)], selected = c(LETTERS, letters)[ids[2]])
			)
		})

		output$float_letters_AB = shiny::renderPlot({
			pal = tab_vals$pal

			if (!length(pal)) return(NULL)
			ids = c(which(c(LETTERS,letters) == input$float_col1),
					which(c(LETTERS,letters) == input$float_col2))
			if (length(ids) == 2) {
				c4a_plot_text(pal[ids], words = c(LETTERS, letters)[ids], dark = input$dark, size = 1.25, frame = TRUE)
			}
		})

		output$floating_rings = shiny::renderPlot({
			if (!length(tab_vals$pal)) return(NULL)
			if (!input$float_original) {
				pal = tab_vals$pal

				ids = c(which(c(LETTERS,letters) == input$float_col1),
						which(c(LETTERS,letters) == input$float_col2))

				if (input$float_rev) ids = rev(ids)
				c4a_plot_floating_rings(col1 = pal[ids[2]], col2 = pal[ids[1]], dark = input$dark)
			} else {
				cols = c("#FF0000", "#0000FF")
				if (input$float_rev) cols = rev(cols)
				c4a_plot_floating_rings(cols[1], cols[2])
			}
		})




		##############################
		## Application tab
		##############################

		output$MAPplot = shiny::renderPlot({
			if (!length(tab_vals$pal)) return(NULL)

			pal = tab_vals$pal
			c4a_plot_map(pal, borders = input$MAPborders, lwd = input$MAPlwd, dark = input$dark, dist = input$MAPdist)
		})

		output$DOTplot = shiny::renderPlot({
			if (!length(tab_vals$pal)) return(NULL)

			pal = tab_vals$pal
			c4a_plot_scatter(pal,  borders = input$DOTborders, lwd = input$DOTlwd, dark = input$dark, dist = input$DOTdist)
		})

		output$TXTplot1 = shiny::renderPlot({
			if (!length(tab_vals$pal)) return(NULL)

			pal = tab_vals$pal
			c4a_plot_text(pal, dark = input$dark)
		})

		output$TXTplot2 = shiny::renderPlot({
			if (!length(tab_vals$pal)) return(NULL)

			pal = tab_vals$pal
			c4a_plot_text(pal, dark = input$dark, frame = TRUE)
		})


		##############################
		## Application tab
		##############################

		observeEvent(input$info, {
			shiny::showModal(shiny::modalDialog(title = "Background",
												shiny::includeMarkdown(system.file("markdown/overview.md", package = "cols4all")),
												footer = shiny::modalButton("Close"),
												style = "color: #000000;"))
		})

	}
	shiny::shinyApp(ui = ui, server = server)
}
