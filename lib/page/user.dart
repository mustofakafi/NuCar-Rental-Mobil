import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rental_app/page/login.dart';

class UserPage extends StatefulWidget {
  final String name;
  const UserPage({Key? key, required this.name}) : super(key: key);

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  int _currentIndex = 0;

  // Fetch cars from the API
  Future<List<dynamic>> _fetchCars() async {
    final url = Uri.parse('http://127.0.0.1:8000/api/product');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('data')) {
        return List.from(data['data']);
      } else {
        throw Exception('Key "data" not found in the API response');
      }
    } else {
      throw Exception('Failed to load cars');
    }
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
        automaticallyImplyLeading: false,
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
        items: _userNavigationItems(),
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black26,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildOrders();
      case 2:
        return _buildProfil();
      case 3:
        return _buildSettings();
      default:
        return Center(child: Text("Page not found"));
    }
  }

Widget _buildHomePage() {
  return Scaffold(
    body: Column(
      children: [
        // Menambahkan judul di atas sebelum daftar mobil
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            'Selamat datang di layanan sewa mobil kami. '
            'NuCar hadir sebagai solusi transportasi yang'
            'mudah dan terpercaya. Kami menyediakan beragam kendaraan. '
            'Semua armada terawat dan diasuransikan, '
            'dengan proses pemesanan mudah, cepat, dan harga kompetitif. ' 
            'NuCar siap menjadi mitra perjalanan Anda.',
             textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            'Daftar Mobil',
             textAlign: TextAlign.justify,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        
        // Bagian FutureBuilder untuk menampilkan daftar mobil
        FutureBuilder<List<dynamic>>(
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
              return Expanded(
                child: ListView.builder(
                  itemCount: cars.length,
                  itemBuilder: (context, index) {
                    final car = cars[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: car['image_url'] != null &&
                                car['image_url'].toString().isNotEmpty
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
                        title: Text(car['nama']?.toString() ?? 'Car Name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kategori: ${car['kategori'] ?? 'kategori'}'),
                            Text('Kapasitas: ${car['kapasitas_penumpang'] ?? 'kapasitas_penumpang'}'),
                            Text('Harga: Rp ${car['tarif_sewa'] ?? 'tarif_sewa'} / hari'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _showCarDetails(car),
                              child: const Text('Pesan Sekarang'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
      ],
    ),
  );
}


void _showCarDetails(dynamic car) {
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, 
    isDismissible: false,  
    enableDrag: false,     
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(  
          child: Center(  
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              crossAxisAlignment: CrossAxisAlignment.center,  
              children: [
                if (car['image_url'] != null && car['image_url'].toString().isNotEmpty)
                  Image.network(
                    car['image_url'].toString(),
                    width: double.infinity,  
                    height: 200,  
                    fit: BoxFit.cover,  
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.car_rental, size: 100);  // Fallback icon
                    },
                  ),
                const SizedBox(height: 16),
                Text(
                  car['nama']?.toString() ?? 'Car Name',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,  // Center the text
                ),
                const SizedBox(height: 8),
                Text(
                  'Kategori: ${car['kategori'] ?? 'kategori'}',
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Kapasitas: ${car['kapasitas_penumpang'] ?? 'kapasitas_penumpang'}',
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Harga: Rp ${car['tarif_sewa'] ?? 'tarif_sewa'} / hari',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _startDateController,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Pinjam',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      _startDateController.text = pickedDate.toString().split(' ')[0];
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _endDateController,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Kembali',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      _endDateController.text = pickedDate.toString().split(' ')[0];
                    }
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Space out the buttons evenly
                  children: [
                    // Pesan Button
                    ElevatedButton(
                      onPressed: () {
                        print("Mobil telah dipesan: ${_startDateController.text} - ${_endDateController.text}");

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Pesanan berhasil!'),
                            duration: const Duration(seconds: 2), // Durasi SnackBar
                          ),
                        );

                       
                        Navigator.pop(context); 
                      },
                      child: const Text('Pesan'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey, 
                      ),
                      onPressed: () {
                        Navigator.pop(context); 
                      },
                      child: const Text('Batal'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


Widget _buildOrders() {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16.0),  // Add padding to the body
      child: SingleChildScrollView( 
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
    // Arahkan pengguna kembali ke halaman login setelah tombol logout ditekan
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }


  List<BottomNavigationBarItem> _userNavigationItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: "Pesanan"),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    ];
  }
}
