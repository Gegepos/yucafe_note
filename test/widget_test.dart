import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yucafe_note_mobile/ui/widgets/loader.dart';
import 'package:yucafe_note_mobile/utils/image_utils.dart';

void main() {
  group('加载动画组件', () {
    testWidgets('AppLoading 渲染圆环、咖啡图标与文案', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AppLoading(text: '正在加载数据…')),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('正在加载数据…'), findsOneWidget);
      expect(find.byIcon(Icons.coffee), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('CardListSkeleton 按 count 渲染骨架卡片', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: CardListSkeleton(count: 3)),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Card), findsNWidgets(3));
      expect(find.byType(ShimmerBox), findsNWidgets(3 * 4));
    });
  });

  group('ImageUtils.resolveUrl', () {
    test('空值与占位字符串返回空串', () {
      expect(ImageUtils.resolveUrl(null), '');
      expect(ImageUtils.resolveUrl(''), '');
      expect(ImageUtils.resolveUrl('null'), '');
      expect(ImageUtils.resolveUrl('<null>'), '');
    });

    test('完整 http(s) 地址原样返回', () {
      expect(ImageUtils.resolveUrl('https://a.com/x.png'), 'https://a.com/x.png');
      expect(ImageUtils.resolveUrl('http://1.2.3.4:8080/a.png'),
          'http://1.2.3.4:8080/a.png');
    });

    test('相对路径拼上图片域名', () {
      expect(ImageUtils.resolveUrl('/beans-images/abc.jpg'),
          '$_imageBase/beans-images/abc.jpg');
    });

    test('既不是绝对地址也不是 / 开头的返回空串', () {
      expect(ImageUtils.resolveUrl('abc.png'), '');
    });
  });
}

/// 与 AppConstants.imageBaseUrl 的默认值保持一致。
const String _imageBase = String.fromEnvironment(
  'IMAGE_BASE_URL',
  defaultValue: 'http://localhost:8080',
);
