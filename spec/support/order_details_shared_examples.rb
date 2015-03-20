shared_examples 'it does not complete order' do
  it 'leaves fulfilled_at nil' do
    expect(order_detail.reload.fulfilled_at).to be_nil
  end

  it 'leaves price policy nil' do
    expect(order_detail.reload.price_policy).to be_nil
  end

  it 'is not a problem order' do
    expect(order_detail.reload).to_not be_problem
  end

  it 'is not complete' do
    expect(order_detail.reload.state).to_not eq('complete')
  end

  it 'does not set actual end at' do
    expect(order_detail.reservation.reload.actual_end_at).to be_nil
  end
end

