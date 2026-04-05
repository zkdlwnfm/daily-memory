package com.dailymemory.presentation.reminder

import android.Manifest
import android.location.Address
import android.location.Geocoder
import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dailymemory.data.service.GeofenceService
import com.dailymemory.domain.model.LocationTriggerType
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.Locale
import javax.inject.Inject

/**
 * Data class representing a selected location
 */
data class SelectedLocation(
    val name: String,
    val address: String?,
    val latitude: Double,
    val longitude: Double,
    val radius: Double = 100.0,
    val triggerType: LocationTriggerType = LocationTriggerType.ENTER
)

@OptIn(ExperimentalMaterial3Api::class, ExperimentalPermissionsApi::class)
@Composable
fun LocationPickerScreen(
    initialLocation: SelectedLocation? = null,
    onNavigateBack: () -> Unit,
    onLocationSelected: (SelectedLocation) -> Unit,
    viewModel: LocationPickerViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val focusManager = LocalFocusManager.current

    val locationPermissions = rememberMultiplePermissionsState(
        permissions = buildList {
            add(Manifest.permission.ACCESS_FINE_LOCATION)
            add(Manifest.permission.ACCESS_COARSE_LOCATION)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                add(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
            }
        }
    )

    LaunchedEffect(Unit) {
        if (initialLocation != null) {
            viewModel.setInitialLocation(initialLocation)
        }

        if (!locationPermissions.allPermissionsGranted) {
            locationPermissions.launchMultiplePermissionRequest()
        } else {
            viewModel.getCurrentLocation()
        }
    }

    LaunchedEffect(locationPermissions.allPermissionsGranted) {
        if (locationPermissions.allPermissionsGranted) {
            viewModel.getCurrentLocation()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Select Location") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.getCurrentLocation() }) {
                        Icon(Icons.Default.MyLocation, "My Location")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Search Bar
            OutlinedTextField(
                value = uiState.searchQuery,
                onValueChange = { viewModel.updateSearchQuery(it) },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("Search for a place...") },
                leadingIcon = {
                    Icon(Icons.Default.Search, null)
                },
                trailingIcon = {
                    if (uiState.searchQuery.isNotEmpty()) {
                        IconButton(onClick = { viewModel.clearSearch() }) {
                            Icon(Icons.Default.Clear, "Clear")
                        }
                    }
                },
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(
                    onSearch = {
                        focusManager.clearFocus()
                        viewModel.search()
                    }
                )
            )

            // Search Results
            if (uiState.searchResults.isNotEmpty()) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 200.dp),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    LazyColumn {
                        items(uiState.searchResults) { result ->
                            SearchResultItem(
                                result = result,
                                onClick = {
                                    viewModel.selectSearchResult(result)
                                    focusManager.clearFocus()
                                }
                            )
                        }
                    }
                }
            }

            // Selected Location Card
            if (uiState.selectedLocation != null) {
                val selected = uiState.selectedLocation!!

                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        // Location Info
                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.LocationOn,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(32.dp)
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Column {
                                Text(
                                    selected.name,
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.SemiBold
                                )
                                if (selected.address != null) {
                                    Text(
                                        selected.address,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                                Text(
                                    "${String.format("%.4f", selected.latitude)}, ${String.format("%.4f", selected.longitude)}",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.outline
                                )
                            }
                        }

                        HorizontalDivider()

                        // Radius Slider
                        Column {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(
                                    "Radius",
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Medium
                                )
                                Text(
                                    "${uiState.radius.toInt()}m",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.primary
                                )
                            }
                            Slider(
                                value = uiState.radius.toFloat(),
                                onValueChange = { viewModel.updateRadius(it.toDouble()) },
                                valueRange = 50f..500f,
                                steps = 8
                            )
                        }

                        // Trigger Type
                        Column {
                            Text(
                                "Trigger when I...",
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.Medium
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                TriggerTypeButton(
                                    type = LocationTriggerType.ENTER,
                                    isSelected = uiState.triggerType == LocationTriggerType.ENTER,
                                    onClick = { viewModel.updateTriggerType(LocationTriggerType.ENTER) },
                                    modifier = Modifier.weight(1f)
                                )
                                TriggerTypeButton(
                                    type = LocationTriggerType.EXIT,
                                    isSelected = uiState.triggerType == LocationTriggerType.EXIT,
                                    onClick = { viewModel.updateTriggerType(LocationTriggerType.EXIT) },
                                    modifier = Modifier.weight(1f)
                                )
                                TriggerTypeButton(
                                    type = LocationTriggerType.BOTH,
                                    isSelected = uiState.triggerType == LocationTriggerType.BOTH,
                                    onClick = { viewModel.updateTriggerType(LocationTriggerType.BOTH) },
                                    modifier = Modifier.weight(1f)
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                // Confirm Button
                Button(
                    onClick = {
                        val location = selected.copy(
                            radius = uiState.radius,
                            triggerType = uiState.triggerType
                        )
                        onLocationSelected(location)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Icon(Icons.Default.Check, null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Use This Location", fontWeight = FontWeight.SemiBold)
                }
            } else {
                // Manual Coordinate Input
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Text(
                            "Or enter coordinates manually",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Medium
                        )

                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            OutlinedTextField(
                                value = uiState.manualLatitude,
                                onValueChange = { viewModel.updateManualLatitude(it) },
                                label = { Text("Latitude") },
                                modifier = Modifier.weight(1f),
                                singleLine = true,
                                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next)
                            )

                            OutlinedTextField(
                                value = uiState.manualLongitude,
                                onValueChange = { viewModel.updateManualLongitude(it) },
                                label = { Text("Longitude") },
                                modifier = Modifier.weight(1f),
                                singleLine = true,
                                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                                keyboardActions = KeyboardActions(
                                    onDone = {
                                        focusManager.clearFocus()
                                        viewModel.useManualCoordinates()
                                    }
                                )
                            )
                        }

                        Button(
                            onClick = { viewModel.useManualCoordinates() },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = uiState.manualLatitude.isNotEmpty() && uiState.manualLongitude.isNotEmpty()
                        ) {
                            Text("Use Coordinates")
                        }
                    }
                }

                // Current Location Button
                if (uiState.currentLocation != null) {
                    OutlinedButton(
                        onClick = { viewModel.useCurrentLocation() },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.MyLocation, null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Use My Current Location")
                    }
                }
            }

            // Loading indicator
            if (uiState.isLoading) {
                Box(
                    modifier = Modifier.fillMaxWidth(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(modifier = Modifier.size(24.dp))
                }
            }
        }
    }
}

@Composable
private fun SearchResultItem(
    result: SearchResult,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.LocationOn,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(
                    result.name,
                    style = MaterialTheme.typography.bodyMedium
                )
                if (result.address != null) {
                    Text(
                        result.address,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
    HorizontalDivider()
}

@Composable
private fun TriggerTypeButton(
    type: LocationTriggerType,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val icon = when (type) {
        LocationTriggerType.ENTER -> Icons.Default.ArrowDownward
        LocationTriggerType.EXIT -> Icons.Default.ArrowUpward
        LocationTriggerType.BOTH -> Icons.Default.SwapVert
    }

    Surface(
        onClick = onClick,
        modifier = modifier,
        shape = RoundedCornerShape(8.dp),
        color = if (isSelected)
            MaterialTheme.colorScheme.primaryContainer
        else
            MaterialTheme.colorScheme.surfaceVariant,
        border = if (isSelected)
            androidx.compose.foundation.BorderStroke(2.dp, MaterialTheme.colorScheme.primary)
        else
            null
    ) {
        Column(
            modifier = Modifier.padding(8.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = if (isSelected)
                    MaterialTheme.colorScheme.primary
                else
                    MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                type.getDisplayName(),
                style = MaterialTheme.typography.labelSmall,
                color = if (isSelected)
                    MaterialTheme.colorScheme.primary
                else
                    MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

// MARK: - ViewModel

data class SearchResult(
    val name: String,
    val address: String?,
    val latitude: Double,
    val longitude: Double
)

data class LocationPickerUiState(
    val searchQuery: String = "",
    val searchResults: List<SearchResult> = emptyList(),
    val selectedLocation: SelectedLocation? = null,
    val currentLocation: SelectedLocation? = null,
    val radius: Double = 100.0,
    val triggerType: LocationTriggerType = LocationTriggerType.ENTER,
    val manualLatitude: String = "",
    val manualLongitude: String = "",
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class LocationPickerViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val geofenceService: GeofenceService
) : ViewModel() {

    private val _uiState = MutableStateFlow(LocationPickerUiState())
    val uiState: StateFlow<LocationPickerUiState> = _uiState.asStateFlow()

    private val geocoder = Geocoder(context, Locale.getDefault())

    fun setInitialLocation(location: SelectedLocation) {
        _uiState.update {
            it.copy(
                selectedLocation = location,
                radius = location.radius,
                triggerType = location.triggerType
            )
        }
    }

    fun updateSearchQuery(query: String) {
        _uiState.update { it.copy(searchQuery = query) }
    }

    fun clearSearch() {
        _uiState.update {
            it.copy(
                searchQuery = "",
                searchResults = emptyList()
            )
        }
    }

    fun search() {
        val query = _uiState.value.searchQuery
        if (query.isBlank()) return

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            try {
                val results = withContext(Dispatchers.IO) {
                    searchLocations(query)
                }
                _uiState.update {
                    it.copy(
                        searchResults = results,
                        isLoading = false
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message
                    )
                }
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun searchLocations(query: String): List<SearchResult> {
        return try {
            val addresses = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val results = mutableListOf<Address>()
                geocoder.getFromLocationName(query, 10) { addresses ->
                    results.addAll(addresses)
                }
                // Give time for async callback
                Thread.sleep(500)
                results
            } else {
                geocoder.getFromLocationName(query, 10) ?: emptyList()
            }

            addresses.map { address ->
                SearchResult(
                    name = address.featureName ?: address.locality ?: "Unknown",
                    address = buildAddress(address),
                    latitude = address.latitude,
                    longitude = address.longitude
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun buildAddress(address: Address): String? {
        return listOfNotNull(
            address.thoroughfare,
            address.locality,
            address.adminArea
        ).takeIf { it.isNotEmpty() }?.joinToString(", ")
    }

    fun selectSearchResult(result: SearchResult) {
        _uiState.update {
            it.copy(
                selectedLocation = SelectedLocation(
                    name = result.name,
                    address = result.address,
                    latitude = result.latitude,
                    longitude = result.longitude,
                    radius = it.radius,
                    triggerType = it.triggerType
                ),
                searchQuery = "",
                searchResults = emptyList()
            )
        }
    }

    fun getCurrentLocation() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            val location = geofenceService.requestCurrentLocation()
            if (location != null) {
                val address = reverseGeocode(location.latitude, location.longitude)
                _uiState.update {
                    it.copy(
                        currentLocation = SelectedLocation(
                            name = address?.name ?: "Current Location",
                            address = address?.address,
                            latitude = location.latitude,
                            longitude = location.longitude
                        ),
                        isLoading = false
                    )
                }
            } else {
                _uiState.update { it.copy(isLoading = false) }
            }
        }
    }

    fun useCurrentLocation() {
        _uiState.value.currentLocation?.let { current ->
            _uiState.update {
                it.copy(
                    selectedLocation = current.copy(
                        radius = it.radius,
                        triggerType = it.triggerType
                    )
                )
            }
        }
    }

    fun updateManualLatitude(value: String) {
        _uiState.update { it.copy(manualLatitude = value) }
    }

    fun updateManualLongitude(value: String) {
        _uiState.update { it.copy(manualLongitude = value) }
    }

    fun useManualCoordinates() {
        val lat = _uiState.value.manualLatitude.toDoubleOrNull() ?: return
        val lng = _uiState.value.manualLongitude.toDoubleOrNull() ?: return

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            val address = reverseGeocode(lat, lng)
            _uiState.update {
                it.copy(
                    selectedLocation = SelectedLocation(
                        name = address?.name ?: "Custom Location",
                        address = address?.address,
                        latitude = lat,
                        longitude = lng,
                        radius = it.radius,
                        triggerType = it.triggerType
                    ),
                    isLoading = false
                )
            }
        }
    }

    @Suppress("DEPRECATION")
    private suspend fun reverseGeocode(latitude: Double, longitude: Double): SearchResult? {
        return withContext(Dispatchers.IO) {
            try {
                val addresses = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    val results = mutableListOf<Address>()
                    geocoder.getFromLocation(latitude, longitude, 1) { addresses ->
                        results.addAll(addresses)
                    }
                    Thread.sleep(500)
                    results
                } else {
                    geocoder.getFromLocation(latitude, longitude, 1) ?: emptyList()
                }

                addresses.firstOrNull()?.let { address ->
                    SearchResult(
                        name = address.featureName ?: address.locality ?: "Unknown Location",
                        address = buildAddress(address),
                        latitude = latitude,
                        longitude = longitude
                    )
                }
            } catch (e: Exception) {
                null
            }
        }
    }

    fun updateRadius(radius: Double) {
        _uiState.update { it.copy(radius = radius) }
    }

    fun updateTriggerType(type: LocationTriggerType) {
        _uiState.update { it.copy(triggerType = type) }
    }
}
