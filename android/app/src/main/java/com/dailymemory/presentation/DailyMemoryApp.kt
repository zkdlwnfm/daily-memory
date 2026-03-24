package com.dailymemory.presentation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.People
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.dailymemory.presentation.home.HomeScreen
import com.dailymemory.presentation.memory.MemoryDetailScreen
import com.dailymemory.presentation.person.PersonDetailScreen
import com.dailymemory.presentation.person.PersonEditScreen
import com.dailymemory.presentation.person.PersonListScreen
import com.dailymemory.presentation.record.RecordScreen
import com.dailymemory.presentation.search.SearchScreen
import com.dailymemory.presentation.settings.SettingsScreen

sealed class Screen(
    val route: String,
    val title: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector
) {
    data object Home : Screen("home", "Home", Icons.Filled.Home, Icons.Outlined.Home)
    data object Search : Screen("search", "Search", Icons.Filled.Search, Icons.Outlined.Search)
    data object People : Screen("people", "People", Icons.Filled.People, Icons.Outlined.People)
    data object Settings : Screen("settings", "Settings", Icons.Filled.Settings, Icons.Outlined.Settings)
    data object Record : Screen("record", "Record", Icons.Filled.Add, Icons.Filled.Add)
    data object PersonDetail : Screen("person/{personId}", "Person", Icons.Filled.People, Icons.Outlined.People)
    data object MemoryDetail : Screen("memory/{memoryId}", "Memory", Icons.Filled.Home, Icons.Outlined.Home)
    data object PersonEdit : Screen("person/edit?personId={personId}", "Edit Person", Icons.Filled.People, Icons.Outlined.People)
}

@Composable
fun DailyMemoryApp(
    startWithVoiceRecord: Boolean = false,
    startWithTextRecord: Boolean = false
) {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    val bottomNavItems = listOf(Screen.Home, Screen.Search, Screen.People, Screen.Settings)
    val showBottomBar = currentDestination?.route in bottomNavItems.map { it.route }

    // Handle widget launch - navigate to record screen
    androidx.compose.runtime.LaunchedEffect(startWithVoiceRecord, startWithTextRecord) {
        if (startWithVoiceRecord || startWithTextRecord) {
            navController.navigate(Screen.Record.route) {
                launchSingleTop = true
            }
        }
    }

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    bottomNavItems.forEach { screen ->
                        val selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true
                        NavigationBarItem(
                            icon = {
                                Icon(
                                    imageVector = if (selected) screen.selectedIcon else screen.unselectedIcon,
                                    contentDescription = screen.title
                                )
                            },
                            label = { Text(screen.title) },
                            selected = selected,
                            onClick = {
                                navController.navigate(screen.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        )
                    }
                }
            }
        },
        floatingActionButton = {
            if (showBottomBar) {
                FloatingActionButton(
                    onClick = { navController.navigate(Screen.Record.route) }
                ) {
                    Icon(Icons.Filled.Add, contentDescription = "Add Memory")
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Home.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.Home.route) {
                HomeScreen(
                    onMemoryClick = { memoryId -> navController.navigate("memory/$memoryId") },
                    onReminderClick = { /* Navigate to reminder */ }
                )
            }
            composable(Screen.Search.route) {
                SearchScreen(
                    onMemoryClick = { memoryId -> navController.navigate("memory/$memoryId") }
                )
            }
            composable(Screen.People.route) {
                PersonListScreen(
                    onPersonClick = { personId ->
                        navController.navigate("person/$personId")
                    },
                    onAddPersonClick = {
                        navController.navigate("person/edit?personId=")
                    }
                )
            }
            composable(Screen.Settings.route) {
                SettingsScreen()
            }
            composable(
                route = Screen.PersonDetail.route,
                arguments = listOf(navArgument("personId") { type = NavType.StringType })
            ) { backStackEntry ->
                val personId = backStackEntry.arguments?.getString("personId") ?: ""
                PersonDetailScreen(
                    personId = personId,
                    onNavigateBack = { navController.popBackStack() },
                    onEditClick = { navController.navigate("person/edit?personId=$personId") },
                    onAddMemory = { navController.navigate(Screen.Record.route) }
                )
            }
            composable(
                route = Screen.PersonEdit.route,
                arguments = listOf(
                    navArgument("personId") {
                        type = NavType.StringType
                        nullable = true
                        defaultValue = null
                    }
                )
            ) { backStackEntry ->
                val personId = backStackEntry.arguments?.getString("personId")
                PersonEditScreen(
                    personId = personId,
                    onNavigateBack = { navController.popBackStack() },
                    onSaveComplete = { navController.popBackStack() }
                )
            }
            composable(Screen.Record.route) {
                RecordScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onSaveComplete = { navController.popBackStack() }
                )
            }
            composable(
                route = Screen.MemoryDetail.route,
                arguments = listOf(navArgument("memoryId") { type = NavType.StringType })
            ) { backStackEntry ->
                val memoryId = backStackEntry.arguments?.getString("memoryId") ?: ""
                MemoryDetailScreen(
                    memoryId = memoryId,
                    onNavigateBack = { navController.popBackStack() },
                    onEditClick = { /* Navigate to edit screen */ },
                    onPersonClick = { personId -> navController.navigate("person/$personId") }
                )
            }
        }
    }
}
