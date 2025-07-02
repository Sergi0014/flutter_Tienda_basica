# Tienda Flutter

Una aplicación moderna e intuitiva para la gestión de una tienda, desarrollada en Flutter con operaciones CRUD completas.

## 🚀 Características

- **Gestión de Clientes**: Crear, editar, eliminar y buscar clientes
- **Gestión de Productos**: Administrar inventario con precios y descripciones
- **Gestión de Ventas**: Registrar ventas con cálculos automáticos y estadísticas
- **UI Moderna**: Diseño intuitivo con Material Design 3
- **Animaciones**: Transiciones suaves y efectos visuales atractivos
- **Estado Reactivo**: Manejo de estado con Provider
- **Validaciones**: Formularios robustos con validación en tiempo real

## 🛠️ Tecnologías

- **Flutter**: Framework de desarrollo multiplataforma
- **Provider**: Manejo de estado reactivo
- **HTTP**: Comunicación con API REST
- **Material Design 3**: Sistema de diseño moderno
- **Flutter Staggered Animations**: Animaciones avanzadas

## 📱 Pantallas

1. **Dashboard Principal**: Vista general con acceso rápido a todas las funciones
2. **Clientes**: Lista, búsqueda y formularios de clientes
3. **Productos**: Gestión completa del inventario
4. **Ventas**: Registro de ventas con estadísticas en tiempo real

## 🎯 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── config/                   # Configuraciones
│   ├── api_config.dart      # Configuración de la API
│   └── app_theme.dart       # Temas y estilos
├── models/                   # Modelos de datos
│   ├── cliente.dart
│   ├── producto.dart
│   └── venta.dart
├── services/                 # Servicios de API
│   ├── base_api_service.dart
│   ├── cliente_service.dart
│   ├── producto_service.dart
│   └── venta_service.dart
├── providers/                # Proveedores de estado
│   ├── cliente_provider.dart
│   ├── producto_provider.dart
│   └── venta_provider.dart
├── screens/                  # Pantallas de la aplicación
│   ├── home_screen.dart
│   ├── clientes/
│   ├── productos/
│   └── ventas/
├── widgets/                  # Widgets reutilizables
│   ├── custom_card.dart
│   ├── loading_widget.dart
│   ├── error_widget.dart
│   ├── empty_state_widget.dart
│   └── fade_in_animation.dart
└── utils/                    # Utilidades
    ├── exceptions.dart
    └── formatters.dart
```

## 🚀 Instalación y Configuración

### Prerrequisitos

- Flutter SDK (>=3.8.1)
- Dart SDK
- Android Studio / VS Code
- Dispositivo Android/iOS o emulador

### Pasos de Instalación

1. **Clonar el repositorio**

   ```bash
   git clone [url-del-repositorio]
   cd tienda_flutter
   ```

2. **Instalar dependencias**

   ```bash
   flutter pub get
   ```

3. **Configurar la API**

   Edita el archivo `lib/config/api_config.dart` y actualiza la URL base:

   ```dart
   static const String baseUrl = 'http://tu-servidor.com:3000';
   ```

4. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 🔧 Configuración del Backend

La aplicación está diseñada para trabajar con una API REST que debe proporcionar los siguientes endpoints:

### Clientes

- `GET /client` - Obtener todos los clientes
- `POST /client` - Crear nuevo cliente
- `PUT /client/:id` - Actualizar cliente
- `DELETE /client/:id` - Eliminar cliente

### Productos

- `GET /product` - Obtener todos los productos
- `POST /product` - Crear nuevo producto
- `PUT /product/:id` - Actualizar producto
- `DELETE /product/:id` - Eliminar producto

### Ventas

- `GET /venta` - Obtener todas las ventas
- `POST /venta` - Crear nueva venta
- `PUT /venta/:id` - Actualizar venta
- `DELETE /venta/:id` - Eliminar venta

## 📋 Estructura de Datos

### Cliente

```json
{
  "id": 1,
  "nombre": "Juan Pérez",
  "email": "juan@example.com"
}
```

### Producto

```json
{
  "id": 1,
  "nombre": "Laptop",
  "precio": 1500000
}
```

### Venta

```json
{
  "id": 1,
  "cantidad": 2,
  "total": 3000000,
  "clienteId": 1,
  "productoId": 1
}
```

## 🎨 Características de UI/UX

- **Material Design 3**: Diseño moderno y consistente
- **Modo Oscuro**: Soporte automático según preferencias del sistema
- **Animaciones**: Transiciones suaves entre pantallas
- **Responsive**: Adaptable a diferentes tamaños de pantalla
- **Accesibilidad**: Cumple con estándares de accesibilidad
- **Validaciones**: Feedback inmediato en formularios

## 🧪 Testing

Ejecutar las pruebas:

```bash
flutter test
```

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.

## 👨‍💻 Desarrollador

Desarrollado como proyecto académico para la gestión moderna de tiendas.
