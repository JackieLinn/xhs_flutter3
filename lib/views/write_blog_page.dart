import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:xhs/services/api_service.dart';

class WriteBlogPage extends StatefulWidget {
  const WriteBlogPage({super.key});

  @override
  State<WriteBlogPage> createState() => _WriteBlogPageState();
}

class _WriteBlogPageState extends State<WriteBlogPage> {
  final PageController _pageController = PageController();
  final List<XFile> _selectedImages = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String _visibility = '公开';
  final List<String> _visibilityOptions = ['公开', '仅自己可见', '仅好友'];

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages.clear();
        _selectedImages.addAll(images);
      });
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImages.clear();
        _selectedImages.add(photo);
      });
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (_selectedImages.isEmpty || title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("请填写完整信息")),
      );
      return;
    }

    try {
      // 上传所有图片到后端接口
      List<String> imageUrls = [];
      for (final image in _selectedImages) {
        final uri = Uri.parse("http://localhost:8088/auth/upload/image");
        final request = http.MultipartRequest("POST", uri);
        request.files.add(await http.MultipartFile.fromPath("file", image.path));

        final streamedResponse = await request.send();
        final responseBody = await streamedResponse.stream.bytesToString();
        final json = jsonDecode(responseBody);

        if (json["code"] != 200 || json["data"] == null) {
          throw Exception("图片上传失败: ${json["message"]}");
        }

        imageUrls.add(json["data"]);
      }

      // 提交发布内容到后端
      await ApiService.postApi("/auth/blog/publish", data: {
        "title": title,
        "content": content,
        "visibility": _visibility,
        "draft": false,
        "isVideo": false,
        "imageUrls": imageUrls,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("发布成功")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("发布失败：$e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSelectPage(),
        _buildEditPage(),
      ],
    );
  }

  Widget _buildSelectPage() {
    return Scaffold(
      appBar: AppBar(title: const Text("选择图片")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: const Text("从相册选择"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text("拍摄照片"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("编辑笔记"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + 1,
                itemBuilder: (_, index) {
                  if (index == _selectedImages.length) {
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.add),
                      ),
                    );
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(_selectedImages[index].path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "添加标题",
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "添加正文",
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: const [
                Chip(label: Text("#美食打卡")),
                Chip(label: Text("#旅行日记")),
                Chip(label: Text("#创作生活")),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.location_on_outlined),
                SizedBox(width: 5),
                Text("标记地点让更多人看到", style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.lock_outline),
                const SizedBox(width: 5),
                const Text("可视范围：", style: TextStyle(color: Colors.grey)),
                DropdownButton<String>(
                  value: _visibility,
                  onChanged: (String? newValue) {
                    setState(() {
                      _visibility = newValue!;
                    });
                  },
                  items: _visibilityOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ElevatedButton(
            onPressed: _publish,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text("发布笔记", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}