import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rental_app/page/login.dart';

class AdminPage extends StatefulWidget {
  final String name;
  final dynamic role;

  const AdminPage({required this.role, required this.name, super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _currentIndex = 0;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _passengerCapacityController = TextEditingController();
  final TextEditingController _tarifSewaController = TextEditingController();

  // Fetch cars from API
  Future<List<dynamic>> _fetchCars() async {
    final url = Uri.parse('http://127.0.0.1:8000/api/product');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return List.from(data['data']);
    } else {
      throw Exception('Failed to load cars');
    }
  }

  // Add a new car
  Future<void> _addCar() async {
    try {
      // 1. Validasi input
      final nama = _nameController.text.trim();
      final kategori = _categoryController.text.trim();
      final kapasitasPenumpang = _passengerCapacityController.text.trim();
      final tarifSewa = _tarifSewaController.text.trim();
      final imageUrl = _imageUrlController.text.trim();

      // 2. Validasi semua field harus diisi
      if (nama.isEmpty || kategori.isEmpty || kapasitasPenumpang.isEmpty || tarifSewa.isEmpty || imageUrl.isEmpty) {
        throw Exception('Semua field harus diisi');
      }

      // 3. Validasi format numerik
      final kapasitas = int.tryParse(kapasitasPenumpang);
      final tarif = double.tryParse(tarifSewa);

      if (kapasitas == null || tarif == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kapasitas penumpang dan tarif sewa harus berupa angka yang valid')),
        );
        return;
      }

      // 4. Persiapkan data untuk dikirim
      final data = {
        'nama': nama,
        'kategori': kategori,
        'kapasitas_penumpang': kapasitas,
        'tarif_sewa': tarif,
        'image_url': imageUrl,
      };

      // 5. Kirim request
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/product/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(data),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // 6. Handle response
      if (response.statusCode == 201) {
        // Sukses
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data mobil berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Parse error message dari response
        final responseData = json.decode(response.body);
        final errorMessage = responseData['message'] ?? 'Gagal menambahkan data mobil';
        throw Exception(errorMessage);
      }
    } catch (error) {
      // 7. Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll('Exception:', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete car data
  Future<void> _deleteCar(int carId) async {
  final url = Uri.parse('http://127.0.0.1:8000/api/product/$carId/hapus');

  try {
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      setState(() {}); // Refresh UI setelah penghapusan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data mobil berhasil dihapus!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final responseData = json.decode(response.body);
      final errorMessage =
          responseData['message'] ?? 'Gagal menghapus data mobil';
      throw Exception(errorMessage);
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceAll('Exception:', '').trim()),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,  // Removes the back button
        title: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'NuCar',
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black26,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddCar,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildCarList();
      case 1:
        return _buildOrders();
      case 2:
        return _buildProfil();
      case 3:
        return _buildSettings();
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  Widget _buildCarList() {
    return FutureBuilder<List<dynamic>>(
      future: _fetchCars(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No cars available'));
        } else {
          final cars = snapshot.data!;
          return ListView.builder(
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final car = cars[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: car['image_url'] != null && car['image_url'].toString().isNotEmpty
                      ? Image.network(
                          car['image_url'].toString(),
                          width: 80,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.car_rental);
                          },
                        )
                      : const Icon(Icons.car_rental),
                  title: Text(car['nama'] ?? 'nama'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kategori: ${car['kategori'] ?? 'kategori'}'),
                      Text('Kapasitas: ${car['kapasitas_penumpang'] ?? 'kapasitas_penumpang'} orang'),
                      Text('Harga: Rp ${car['tarif_sewa'] ?? 'tarif_sewa'} / hari'),
                      const SizedBox(height: 8),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditCar(car), // You can add edit functionality here
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteCar(car['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
  

  Widget _buildOrders() {
  return Scaffold(
    body: SingleChildScrollView( 
      scrollDirection: Axis.horizontal, 
      child: SingleChildScrollView( 
        scrollDirection: Axis.vertical, 
        child: DataTable( 
          columns: const [ 
            DataColumn(label: Text('Detail Mobil')), 
            DataColumn(label: Text('Tanggal Pinjam')), 
            DataColumn(label: Text('Tanggal Mengembalikan')), 
            DataColumn(label: Text('Status')),
          ],
          rows: [], // Tabel kosong tanpa data, Anda bisa menambahkan data dinamis di sini
        ),
      ),
    ),
  );
}


Widget _buildProfil() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Nama: ${widget.name}', style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }


    // Fungsi untuk menampilkan dialog tambah mobil
  void _showAddCar() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Car'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                TextField(
                  controller: _passengerCapacityController,
                  decoration: const InputDecoration(labelText: 'Passenger Capacity'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _tarifSewaController,
                  decoration: const InputDecoration(labelText: 'Tarif Sewa'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                await _addCar();
                if (mounted) setState(() {}); // Refresh data setelah menambah
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

void _showEditCar(Map<String, dynamic> car) {
    _nameController.text = car['nama'] ?? '';
    _categoryController.text = car['kategori'] ?? '';
    _passengerCapacityController.text = car['kapasitas_penumpang']??'';
    _tarifSewaController.text = car['tarif_sewa']?.toString() ?? '';
    _imageUrlController.text = car['image_url'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Mobil'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Mobil'),
                ),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                ),
                TextField(
                  controller: _passengerCapacityController,
                  decoration:
                      const InputDecoration(labelText: 'Kapasitas Penumpang'),
                ),
                TextField(
                  controller: _tarifSewaController,
                  decoration: const InputDecoration(labelText: 'Tarif Sewa'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'URL Gambar'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                await _updateCar(car['id']);
                if (mounted) setState(() {}); // Refresh data setelah edit
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateCar(int carId) async {
  final nama = _nameController.text;
  final kategori = _categoryController.text;
  final imageUrl = _imageUrlController.text;
  final kapasitasPenumpang = _passengerCapacityController.text;
  final tarifSewa = _tarifSewaController.text;

  if (nama.isEmpty ||
      kategori.isEmpty ||
      imageUrl.isEmpty ||
      kapasitasPenumpang.isEmpty ||
      tarifSewa.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Semua field harus diisi')),
    );
    return;
  }

  final url = Uri.parse('http://127.0.0.1:8000/api/product/$carId');

  try {
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nama': nama,
        'kategori': kategori,
        'image_url': imageUrl,
        'kapasitas_penumpang': kapasitasPenumpang,
        'tarif_sewa': double.parse(tarifSewa),
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['message'] == 'Success') {
        Navigator.pop(context);
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data mobil berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(responseData['message'] ?? 'Update gagal');
      }
    } else {
      final responseData = json.decode(response.body);
      throw Exception(responseData['message'] ?? 'Gagal mengupdate data mobil');
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceAll('Exception:', '').trim()),
        backgroundColor: Colors.red,
      ),
    );
  }
}



  Widget _buildSettings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _logout,  // Memanggil langsung fungsi _logout
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}
