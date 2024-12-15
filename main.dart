import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

User? currentUser;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MockDatabase.loadFromFile();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

class User {
  final String username;
  final String password;

  User(this.username, this.password);

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
  };

  static User fromJson(Map<String, dynamic> json) {
    return User(json['username'], json['password']);
  }
}

class Project {
  final String title;
  final String description;
  final String responsiblePerson;
  final DateTime creationDate;
  final String owner;

  Project({
    required this.title,
    required this.description,
    required this.responsiblePerson,
    required this.creationDate,
    required this.owner,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'responsiblePerson': responsiblePerson,
    'creationDate': creationDate.toIso8601String(),
    'owner': owner,
  };

  static Project fromJson(Map<String, dynamic> json) {
    return Project(
      title: json['title'],
      description: json['description'],
      responsiblePerson: json['responsiblePerson'],
      creationDate: DateTime.parse(json['creationDate']),
      owner: json['owner'],
    );
  }
}

class MockDatabase {
  static List<User> users = [];
  static List<Project> projects = [];
  static const String userFile = 'users.json';
  static const String projectFile = 'projects.json';

  static Future<void> saveToFile() async {
    final usersData = jsonEncode(users.map((u) => u.toJson()).toList());
    final projectsData = jsonEncode(projects.map((p) => p.toJson()).toList());

    final userFileHandle = File(userFile);
    final projectFileHandle = File(projectFile);

    await userFileHandle.writeAsString(usersData);
    await projectFileHandle.writeAsString(projectsData);
  }

  static Future<void> loadFromFile() async {
    try {
      final userFileHandle = File(userFile);
      final projectFileHandle = File(projectFile);

      if (await userFileHandle.exists()) {
        final usersData = await userFileHandle.readAsString();
        users = (jsonDecode(usersData) as List)
            .map((user) => User.fromJson(user))
            .toList();
      }

      if (await projectFileHandle.exists()) {
        final projectsData = await projectFileHandle.readAsString();
        projects = (jsonDecode(projectsData) as List)
            .map((project) => Project.fromJson(project))
            .toList();
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() {
    final username = _usernameController.text;
    final password = _passwordController.text;
    final user = MockDatabase.users.firstWhere(
          (user) => user.username == username && user.password == password,
      orElse: () => User('', ''),
    );

    if (user.username.isNotEmpty) {
      currentUser = user;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProjectListPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid login credentials')),
      );
    }
  }

  void _register() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      MockDatabase.users.add(User(username, password));
      await MockDatabase.saveToFile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User registered successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _login, child: Text('Login')),
                ElevatedButton(onPressed: _register, child: Text('Register')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectListPage extends StatefulWidget {
  @override
  _ProjectListPageState createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  void _createProject() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateProjectPage()),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final userProjects = MockDatabase.projects
        .where((project) => project.owner == currentUser?.username)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Projects'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createProject,
          ),
        ],
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _createProject,
            child: Text('Create New Project'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: userProjects.length,
              itemBuilder: (context, index) {
                final project = userProjects[index];
                return ListTile(
                    title: Text(project.title),
                    subtitle: Text(project.description),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProjectDetailPage(project: project),
                      ),
                    ));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CreateProjectPage extends StatefulWidget {
  @override
  _CreateProjectPageState createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _responsiblePersonController = TextEditingController();

  void _saveProject() async {
    final title = _titleController.text;
    final description = _descriptionController.text;
    final responsiblePerson = _responsiblePersonController.text;

    if (title.isNotEmpty && description.isNotEmpty && responsiblePerson.isNotEmpty) {
      final newProject = Project(
        title: title,
        description: description,
        responsiblePerson: responsiblePerson,
        creationDate: DateTime.now(),
        owner: currentUser!.username,
      );
      MockDatabase.projects.add(newProject);
      await MockDatabase.saveToFile();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _responsiblePersonController,
              decoration: InputDecoration(labelText: 'Responsible Person'),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _saveProject, child: Text('Save')),
          ],
        ),
      ),
    );
  }
}

class ProjectDetailPage extends StatelessWidget {
  final Project project;

  ProjectDetailPage({required this.project});

  void _deleteProject(BuildContext context) async {
    MockDatabase.projects.remove(project);
    await MockDatabase.saveToFile();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Project "${project.title}" deleted successfully!')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {

    String formattedDate = '${project.creationDate.day}-${project.creationDate.month}-${project.creationDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(project.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${project.title}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Description: ${project.description}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Responsible Person: ${project.responsiblePerson}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Created On: $formattedDate', style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _deleteProject(context),
              child: Text('Delete Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

