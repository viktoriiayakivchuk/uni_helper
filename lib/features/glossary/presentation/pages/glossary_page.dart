import 'package:flutter/material.dart';
import 'dart:ui';
import '../../domain/glossary_item.dart';

class GlossaryPage extends StatefulWidget {
  const GlossaryPage({super.key});

  @override
  State<GlossaryPage> createState() => _GlossaryPageState();
}

class _GlossaryPageState extends State<GlossaryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Всі';

  final List<String> _categories = ['Всі', 'Навчання', 'Адміністрація', 'Фінанси', 'Побут', 'Права', 'Наука'];

  // Максимально розширений список термінів (Вимога №3)
  final List<GlossaryItem> _allItems = [
    // --- НАВЧАННЯ ---
    GlossaryItem(
      term: 'ECTS (Кредит)', 
      definition: 'Європейська система перенесення і накопичення кредитів. 1 кредит дорівнює 30 академічним годинам. Для отримання диплома бакалавра необхідно опанувати 240 кредитів. Це "валюта" вашого навчання.',
      category: 'Навчання'
    ),
    GlossaryItem(
      term: 'Модульний контроль', 
      definition: 'Перевірка знань після вивчення частини дисципліни. Зазвичай проводиться 2 модулі на семестр. Оцінки сумуються з балами за практичні, формуючи "автомат".',
      category: 'Навчання'
    ),
    GlossaryItem(
      term: 'Силабус', 
      definition: 'Ваш головний документ з предмета. Тут прописано: за що ставлять бали, де брати літературу, графік дедлайнів та правила перескладання.',
      category: 'Навчання'
    ),
    GlossaryItem(
      term: 'Перескладання (Комісія)', 
      definition: 'Остання спроба здати предмет. Якщо не здали іспит з двох спроб, призначається комісія викладачів. Провал на комісії зазвичай веде до відрахування.',
      category: 'Навчання'
    ),
    GlossaryItem(
      term: 'Академічна різниця', 
      definition: 'Перелік предметів, які студент має доздати при переведенні на іншу спеціальність через розбіжності в навчальних планах.',
      category: 'Навчання'
    ),
    GlossaryItem(
      term: 'Вибіркові дисципліни', 
      definition: 'Предмети, які ви обираєте самостійно (25% програми). Можливість вивчати те, що вам цікаво, навіть з інших факультетів.',
      category: 'Навчання'
    ),
    GlossaryItem(
      term: 'Акредитація', 
      definition: 'Державна перевірка якості навчання. Без акредитації університет не має права видавати дипломи державного зразка.',
      category: 'Навчання'
    ),

    // --- АДМІНІСТРАЦІЯ ---
    GlossaryItem(
      term: 'Деканат', 
      definition: 'Центральний офіс факультету. Тут замовляють студентські квитки, довідки про навчання та погоджують індивідуальні графіки.',
      category: 'Адміністрація'
    ),
    GlossaryItem(
      term: 'Вчена рада', 
      definition: 'Колегіальний орган, що приймає стратегічні рішення: від затвердження тем дисертацій до вибору ректора.',
      category: 'Адміністрація'
    ),
    GlossaryItem(
      term: 'Навчальна частина', 
      definition: 'Відділ, що формує розклад пар та іспитів. Якщо в розкладі накладка аудиторій — це питання до них.',
      category: 'Адміністрація'
    ),
    GlossaryItem(
      term: 'Кафедра', 
      definition: 'Базовий підрозділ викладачів вашого профілю. Кожен студент закріплений за кафедрою для вибору наукового керівника.',
      category: 'Адміністрація'
    ),

    // --- ФІНАНСИ ---
    GlossaryItem(
      term: 'Рейтинговий бал', 
      definition: 'Число для черги на стипендію. Складається з середнього балу сесії (90%) та додаткових балів за активність (10%).',
      category: 'Фінанси'
    ),
    GlossaryItem(
      term: 'Податкова знижка', 
      definition: 'Повернення державою 18% вартості контракту. Оформити можуть батьки, які працюють офіційно, або сам студент.',
      category: 'Фінанси'
    ),
    GlossaryItem(
      term: 'Соціальна стипендія', 
      definition: 'Фіксована виплата для пільгових категорій (ВПО, сироти). Не залежить від місця в рейтингу успішності.',
      category: 'Фінанси'
    ),

    // --- ПОБУТ ---
    GlossaryItem(
      term: 'Коворкінг', 
      definition: 'Простір для навчання з Wi-Fi та розетками. Ідеальне місце для роботи над проєктами між парами.',
      category: 'Побут'
    ),
    GlossaryItem(
      term: 'Студентське містечко', 
      definition: 'Комплекс гуртожитків зі своєю адміністрацією, що відповідає за поселення та побутові умови.',
      category: 'Побут'
    ),
    GlossaryItem(
      term: 'Старостат', 
      definition: 'Збори старост груп із деканом факультету для вирішення організаційних питань.',
      category: 'Побут'
    ),

    // --- ПРАВА ---
    GlossaryItem(
      term: 'Академічна свобода', 
      definition: 'Право студента на власний погляд. Викладач не має права занижувати бал через розбіжність у думках.',
      category: 'Права'
    ),
    GlossaryItem(
      term: 'Омбудсмен', 
      definition: 'Захисник інтересів студентів. До нього йдуть у випадках корупції, булінгу або порушення прав.',
      category: 'Права'
    ),
    GlossaryItem(
      term: 'Доброчесність', 
      definition: 'Правила чесного навчання: без плагіату та списування. Порушення може призвести до відрахування.',
      category: 'Права'
    ),

    // --- НАУКА ---
    GlossaryItem(
      term: 'Тези доповіді', 
      definition: 'Короткий виклад дослідження (1-2 сторінки). Дає додаткові бали до стипендіального рейтингу.',
      category: 'Наука'
    ),
    GlossaryItem(
      term: 'Індекс Гірша', 
      definition: 'Показник популярності вченого. Високий індекс свідчить про реальний внесок у науку та цитування колегами.',
      category: 'Наука'
    ),
    GlossaryItem(
      term: 'Unicheck', 
      definition: 'Професійна система перевірки робіт на плагіат. Більшість університетів вимагають унікальність вище 70-80%.',
      category: 'Наука'
    ),
  ];

  List<GlossaryItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = _allItems;
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        final matchesSearch = item.term.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesCategory = _selectedCategory == 'Всі' || item.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F1),
      appBar: AppBar(
        title: const Text('Словничок UniHelper', 
          style: TextStyle(color: Color(0xFF2D5A40), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea( // Забезпечує відступи від країв екрана
        child: Column(
          children: [
            // Пошук
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilters(),
                  decoration: const InputDecoration(
                    hintText: 'Пошук...',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF2D5A40)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            // Селектор категорій
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          _selectedCategory = cat;
                          _applyFilters();
                        });
                      },
                      selectedColor: const Color(0xFF2D5A40),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF2D5A40)),
                    ),
                  );
                },
              ),
            ),

            // Список (Expanded вирішує overflow)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // Нижній відступ 100 для BottomBar
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: ExpansionTile(
                          iconColor: const Color(0xFF2D5A40),
                          title: Text(item.term, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D5A40))),
                          subtitle: Text(item.category, style: const TextStyle(fontSize: 12)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(item.definition, style: const TextStyle(height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}