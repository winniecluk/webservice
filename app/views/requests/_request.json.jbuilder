json.extract! request, :id, :num, :created_at, :updated_at
json.url request_url(request, format: :json)
