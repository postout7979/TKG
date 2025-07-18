# web/web_server.py (이전과 동일, 변경 없음)
from flask import Flask, render_template_string, request, jsonify
import requests
import os

app = Flask(__name__)

# AP 서버의 URL을 환경 변수에서 가져옴
# K8s 환경에서는 ap-service의 내부 DNS 이름으로 접근
AP_SERVER_URL = os.getenv('AP_SERVER_URL', "http://localhost:5001/api/items")

# HTML 템플릿 (이전과 동일)
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Three-Tier Demo App (PostgreSQL)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f4f4f4; color: #333; }
        .container { background-color: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); max-width: 800px; margin: 0 auto; }
        h1, h2 { color: #0056b3; }
        form { margin-bottom: 20px; padding: 15px; border: 1px solid #ddd; border-radius: 5px; background-color: #f9f9f9; }
        form label { display: block; margin-bottom: 5px; font-weight: bold; }
        form input[type="text"], form textarea { width: calc(100% - 22px); padding: 10px; margin-bottom: 10px; border: 1px solid #ccc; border-radius: 4px; }
        form button { background-color: #28a745; color: white; padding: 10px 15px; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; }
        form button:hover { background-color: #218838; }
        #itemsList { border-collapse: collapse; width: 100%; margin-top: 20px; }
        #itemsList th, #itemsList td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        #itemsList th { background-color: #f2f2f2; }
        .message { margin-top: 10px; padding: 10px; border-radius: 4px; }
        .message.success { background-color: #d4edda; color: #155724; border-color: #c3e6cb; }
        .message.error { background-color: #f8d7da; color: #721c24; border-color: #f5c6cb; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Three-Tier DEMO Application v0.2 (PostgreSQL)</h1>

        <h2>새로운 아이템 추가</h2>
        <form id="addItemForm">
            <label for="itemName">이름:</label>
            <input type="text" id="itemName" name="name" required><br>

            <label for="itemDescription">설명:</label>
            <textarea id="itemDescription" name="description"></textarea><br>

            <button type="submit">아이템 추가</button>
            <div id="formMessage" class="message"></div>
        </form>

        <h2>아이템 목록</h2>
        <table id="itemsList">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>이름</th>
                    <th>설명</th>
                </tr>
            </thead>
            <tbody>
                </tbody>
        </table>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            loadItems();

            const addItemForm = document.getElementById('addItemForm');
            const formMessage = document.getElementById('formMessage');

            addItemForm.addEventListener('submit', async function(event) {
                event.preventDefault(); // 기본 폼 제출 방지

                const name = document.getElementById('itemName').value;
                const description = document.getElementById('itemDescription').value;

                try {
                    const response = await fetch('/add_item', { // WEB 서버의 /add_item 엔드포인트로 요청
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ name, description })
                    });
                    const data = await response.json();

                    if (response.ok) {
                        formMessage.className = 'message success';
                        formMessage.textContent = data.message;
                        addItemForm.reset(); // 폼 초기화
                        loadItems(); // 아이템 목록 새로고침
                    } else {
                        formMessage.className = 'message error';
                        formMessage.textContent = data.error || '아이템 추가 실패';
                    }
                } catch (error) {
                    console.error('Error:', error);
                    formMessage.className = 'message error';
                    formMessage.textContent = '네트워크 오류가 발생했습니다.';
                }
            });

            async function loadItems() {
                const itemsListBody = document.querySelector('#itemsList tbody');
                itemsListBody.innerHTML = '<tr><td colspan="3">로딩 중...</td></tr>';
                try {
                    const response = await fetch('/get_items'); // WEB 서버의 /get_items 엔드포인트로 요청
                    const items = await response.json();

                    itemsListBody.innerHTML = ''; // 기존 목록 지우기
                    if (items.length === 0) {
                        itemsListBody.innerHTML = '<tr><td colspan="3">아이템이 없습니다.</td></tr>';
                    } else {
                        items.forEach(item => {
                            const row = itemsListBody.insertRow();
                            row.insertCell().textContent = item.id;
                            row.insertCell().textContent = item.name;
                            row.insertCell().textContent = item.description || ''; // 설명이 없을 수 있으므로 빈 문자열 처리
                        });
                    }
                } catch (error) {
                    console.error('Error loading items:', error);
                    itemsListBody.innerHTML = '<tr><td colspan="3" class="message error">아이템을 불러오는 데 실패했습니다.</td></tr>';
                }
            }
        });
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    """메인 페이지를 렌더링합니다."""
    return render_template_string(HTML_TEMPLATE)

@app.route('/get_items', methods=['GET'])
def get_items_from_ap():
    """AP 서버로부터 아이템 목록을 가져와 클라이언트에 전달합니다."""
    try:
        response = requests.get(AP_SERVER_URL)
        response.raise_for_status() # HTTP 에러 발생 시 예외 발생
        return jsonify(response.json()), 200
    except requests.exceptions.RequestException as e:
        print(f"AP 서버 통신 오류 (GET): {e}")
        return jsonify({"error": "아이템을 가져오는 중 AP 서버와 통신 오류 발생"}), 500

@app.route('/add_item', methods=['POST'])
def add_item_to_ap():
    """클라이언트로부터 받은 아이템을 AP 서버에 전달합니다."""
    if not request.is_json:
        return jsonify({"error": "요청은 JSON 형식이어야 합니다."}), 400

    data = request.get_json()

    try:
        response = requests.post(AP_SERVER_URL, json=data)
        response.raise_for_status() # HTTP 에러 발생 시 예외 발생
        return jsonify(response.json()), response.status_code
    except requests.exceptions.RequestException as e:
        print(f"AP 서버 통신 오류 (POST): {e}")
        return jsonify({"error": "아이템 추가 중 AP 서버와 통신 오류 발생"}), 500

if __name__ == '__main__':
    print("WEB 계층 서버 시작 중...")
    app.run(host='0.0.0.0', port=5000, debug=True)
