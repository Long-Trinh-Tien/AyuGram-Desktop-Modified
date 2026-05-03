# Bug: `MediaView` weak_ptr expired khi download async hoàn tất

## Triệu chứng
Khi copy/export nhiều tin nhắn có ảnh, chỉ những ảnh ở gần vùng nhìn hiện tại (viewport) mới được download. Các ảnh ở xa (scroll lên trên) bị bỏ qua và hiển thị `[ Photo ]` thay vì ảnh thật.

## Debug

### Bước 1: Xác nhận vấn đề không phải do thiếu `MediaView`
- Ban đầu nghĩ rằng `MediaView` chưa được tạo trước khi `p->load()` gọi
- Fix: tạo `MediaView` trong pass 1, ngay trước `p->load()` — vẫn không hết lỗi

### Bước 2: Kiểm tra `p->loading()` và `pMedia->loaded()`
- Pass 1: `p->load()` bắt đầu download async
- Pass 2: tạo `pMedia`, chờ `pMedia->loaded()`
- Download hoàn tất nhưng `pMedia->loaded()` vẫn false

### Bước 3: Đọc code `PhotoData::load()` (`data/data_photo.cpp:334`)
```cpp
const auto done = [=](QImage result, QByteArray bytes) {
    if (const auto active = activeMediaView()) {
        active->set(validSize, goodFor, ..., std::move(bytes));
    }
    if (validSize == PhotoSize::Large && goodFor == validSize) {
        _owner->photoLoadDone(this);
    }
};
```

Callback `done` chỉ gọi `active->set(...)` nếu `activeMediaView()` trả về non-null.

### Bước 4: Phát hiện root cause — `weak_ptr` expired
```cpp
// data/data_photo.cpp:393
std::shared_ptr<PhotoMedia> PhotoData::createMediaView() {
    auto result = std::make_shared<PhotoMedia>(this);
    _media = result;         // _media là weak_ptr<PhotoMedia>
    return result;
}

// data/data_photo.cpp:398
std::shared_ptr<PhotoMedia> PhotoData::activeMediaView() const {
    return _media.lock();     // trả về null nếu shared_ptr đã bị hủy
}
```

Khi code copy tạo `MediaView`:
```cpp
auto pMedia = p->createMediaView();  // shared_ptr, _media = result (weak)
p->load(...);
// pMedia hết scope → shared_ptr destructor chạy → reference count = 0
// → PhotoMedia bị delete
// → _media.lock() trả về null
```

Khi download async hoàn tất, callback `done` chạy:
- `activeMediaView()` → `_media.lock()` → null → không set ảnh vào MediaView

## Fix

Giữ `shared_ptr<Data::PhotoMedia>` sống đến hết hàm bằng `static vector`:

```cpp
static std::vector<std::shared_ptr<Data::PhotoMedia>> keepMediaAlive;
keepMediaAlive.clear();

for (const auto &[item, selection] : _selected) {
    if (const auto p = media->photo()) {
        auto pMedia = p->activeMediaView();
        if (!pMedia) pMedia = p->createMediaView();
        keepMediaAlive.push_back(pMedia);  // Giữ shared_ptr sống
        p->load(Data::PhotoSize::Large, item->fullId());
    }
}
```

Nhờ đó, khi callback `done` chạy, `_media.lock()` trả về `PhotoMedia` còn sống → `active->set(...)` được gọi → ảnh được set vào MediaView → `pMedia->loaded()` trả về true.

## Files affected
- `Telegram/SourceFiles/history/history_inner_widget.cpp` — `copySelectedText()`, `exportSelectedText()`
- `Telegram/SourceFiles/history/view/history_view_list_widget.cpp` — `copySelected()`, `exportSelected()`
