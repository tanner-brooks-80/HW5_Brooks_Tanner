library("ggplot2")
library("ggthemes")
library("plotly")
library("viridis")
library("htmlwidgets")
library("tidyverse")
library("shiny")
library("shinydashboard")
library("DT")
library("reshape2")

nfl <- read.csv("Football2021.csv")

nfl <- subset(nfl, select = -c(Pos, FPTS, DeffenseScore))
names(nfl) <- c("Week", "Team_Abr", "Team", "Home_Game", "Score", "Opponent_Score", "Opponent",
                "Tackle_For_Loss", "Sacks", "QB_Hits", "Defense_Interceptions", "Fumble_Recovery",
                "Safeties", "Defense_TD's", "Return_TD's", "Points_Allowed", "Defensive_Fantasy_Points",
                "Win", "Turn_Overs", "Score_Spread", "Pass_Yards", "Pass_TD's", "Offensive_Interceptions",
                "Rush_Yards", "Rush_TD's", "Completed_Passes", "Recieving_Yards", "Recieving_TD's", "Fumbles_Lost",
                "Offensive_Fantasy_Points", "Field_Goals_Made", "Field_Goals_Attempted", "Field_Goal_PercMade",
                "Longest_Field_Goal", "Extra_Points_Made", "Extra_Points_Attempted", "Kicker_Fantasy_Points",
                "Pass_Yards_Allowed", "Rush_Yards_Allowed", "Kicker_Fantasy_Pts_Allowed"
)

nfl = nfl %>% group_by(Team_Abr) %>% arrange(Week) %>% mutate(Team_Record = cumsum(Win))
nfl$Win_Percentage <- nfl$Team_Record / nfl$Week
nfl$Score <- round(nfl$Score)
nfl$Week <- round(nfl$Week)
nfl$Win_Percentage <- round(nfl$Win_Percentage, 2)
nfl$Fantasy_Points <- nfl$Offensive_Fantasy_Points + nfl$Defensive_Fantasy_Points + nfl$Kicker_Fantasy_Points


nfl$Division <- NA
nfl$Division[nfl$Team_Abr %in% c("DEN", "KC", "LAC", "LV")] <- "AFC West"
nfl$Division[nfl$Team_Abr %in% c("NE", "BUF", "MIA", "NYJ")] <- "AFC East"
nfl$Division[nfl$Team_Abr %in% c("CIN", "PIT", "BAL", "CLE")] <- "AFC North"
nfl$Division[nfl$Team_Abr %in% c("HOU", "IND", "JAX", "TEN")] <- "AFC South"

nfl$Division[nfl$Team_Abr %in% c("ARI", "SEA", "SF", "LAR")] <- "NFC West"
nfl$Division[nfl$Team_Abr %in% c("WAS", "DAL", "NYG", "PHI")] <- "NFC East"
nfl$Division[nfl$Team_Abr %in% c("MIN", "GB", "DET", "CHI")] <- "NFC North"
nfl$Division[nfl$Team_Abr %in% c("TB", "ATL", "NO", "CAR")] <- "NCF South"


# west <- subset(nfl, Team_Abr %in% c("DEN", "KC", "LAC", "LV"))


box_data <- subset(nfl, select = c(Division, Team, Score, Opponent_Score))
names(box_data) <- c("Division", "Team", "Offense", "Defense")
box_data <- melt(box_data, id.vars = c("Division", "Team"), measure.vars = c("Offense","Defense"))
names(box_data) <- c("Division", "Team", "Position", "Points")






ui <- dashboardPage(
    
    # format
    skin="blue",
    
    # define the title
    dashboardHeader(
        title="NFL Divisional Statistics"
    ),
    
    # define the sidebar
    dashboardSidebar(
        # set sidebar menu
        sidebarMenu(
            textInput("in_name","Division",value="AFC West"),
            menuItem("Fantasy Football Points & Winning %", tabName = "by_year"),
            menuItem("Offense vs. Defense", tabName = "off_vs_def"),
            menuItem("Total Data", tabName = "raw_data"),
            menuItem("Purpose of Dashboard", tabName = "purpose")
        )
    ),
    
    # define the body
    dashboardBody(
        tabItems(
            
            
            # first page
            tabItem(
                
                "by_year",
                h2("Winning % and Fantasy Football Points Scored per Game by ",textOutput("in_name1", inline=TRUE)," Division (2021)"),
                box(plotlyOutput("p_timeseries"), width= 500)
                
            ),
            
            
            # second page
            tabItem(
                
                "off_vs_def",
                h2("Points Scored and Points Allowed by Team in the ",textOutput("in_name2", inline=TRUE), " Division (2021)"),
                box(plotOutput("p_hist_similar"), width= 500)
                
            ),
            
            
            
            # third page
            tabItem(
                "raw_data",
                h2("Total Team Statistics in ",textOutput("in_name3", inline=TRUE), " Division (2021)"),
                box(dataTableOutput("t_similar"), width= 500)
                
            ),
            
            
            
            # fourth page
            tabItem(
                "purpose",
                p("Possible values that can be used in the search bar: "), strong("AFC North, AFC South, AFC East, AFC West, NFC North, 
                                                                 NFC South, NFC East, NFC West"),
                h3("Dashboard Motivation"),
                p("The motivation behind this dashboard is to visualize the NFL Fantasy Football and team statstics. I especially
        want to show the impact of scoring on both defense and offense and their winning chances."),
                h3("What I Want to Communicate / Why I Chose Each Figure/Table"),
                p("For the first tab, I want to show the impact of total fantasy football points per team and their overall winning 
        percentage. As an example, if we look at the Kansas City Chiefs, we can see that in the beginning they were scoring 
        a lot of fantasy football points per game and their winning percentage was high. As the weeks went on we see that 
        their total points started to dip and so did their record. As the season progresses, they start getting more 
        fantasy points and their winning percentage gets larger."),
                p("For the second tab, I want to show the contrast of each team's offensive points and defensive points allowed."),
                p("For the third tab I want to provide an interactive table that contains all the raw data of each of the NFL teams. 
        This allows the user to see the breakdown of each team's statistics such as total offensive passing yards, running 
        yards, touchdowns and total defensive passing yards allowed, running yards allowed and touchdowns allowed. The table 
        gives the user an in-depth and comprehensive analysis into comparing teams at all different levels."),
                h3("Options for User"),
                p("The user is able to interact with the first plot to see and compare each team within their respective division 
        winning percentages and total fantasy football points scored for a given week. The other option the user has 
        to interact and dig around in the data more is the 'Search' feature in the left panel. To use this search 
        navigation, the user will type in a divisional region. There are a total of eight regions and can take in the 
        following values: "),
                strong("AFC North, AFC South, AFC East, AFC West, NFC North, NFC South, NFC East, NFC West")
                
            )
            
            
            
        )
    )
    
)




server <- function(input, output) {
    
    # --------------------------------------------------
    # define the name for titling
    # --------------------------------------------------
    # define the name twice to be used twice above
    
    output$in_name1 <- renderText({
        input$in_name
    })
    output$in_name2 <- renderText({
        input$in_name
    })
    output$in_name3 <- renderText({
        input$in_name
    })
    output$in_name4 <- renderText({
        input$in_name
    })
    
    # --------------------------------------------------
    # Time Series of Winning % and Fantasy Points 
    # --------------------------------------------------
    output$p_timeseries <- renderPlotly({
        
        in_name <-  input$in_name
        
        p_gm <- ggplot(data = nfl %>% filter(Division==in_name),
                       mapping = aes(x = Week,
                                     y = Fantasy_Points,
                                     color=Team)) + 
            geom_point(alpha=0.35, shape=16, aes(size = Win_Percentage)) +
            geom_smooth(method = "loess", se = F) +
            ylab("Total Fantasy Points Scored") +
            xlab("Week") +
            guides(size = "none") +
            scale_color_viridis(discrete = TRUE) + 
            theme_tufte(base_size=12, base_family = "sans")
        
        
        p_i <- ggplotly(p_gm)
        p_i
        
    })
    
    # --------------------------------------------------
    # Boxplot comparisons of Offense Scoring & Defensive Points Allowed
    # --------------------------------------------------
    output$p_hist_similar <- renderPlot({
        
        in_name <-  input$in_name
        
        p_gm <- ggplot(data = box_data %>% filter(Division==in_name),
                       mapping = aes(x = Team,
                                     y = Points,
                                     fill = Position)) + 
            geom_boxplot(alpha=0.40, shape=16) +
            scale_fill_manual(values=c("#DCE319FF", "#481567FF")) +
            ylab("Scores") +
            xlab("Team") +
            guides(size = "none") +
            theme_tufte(base_size=12, base_family = "sans")
        
        p_gm
        
    })
    
    # --------------------------------------------------
    # table of all stats
    # --------------------------------------------------
    output$t_similar <- DT::renderDataTable({
        
        in_name <-  input$in_name
        
        DT::datatable(data = nfl %>% filter(Division==in_name),
                      options = list(scrollX = TRUE, scrollY = "500px"),
        )
        
    })
    
}

shinyApp(ui, server)